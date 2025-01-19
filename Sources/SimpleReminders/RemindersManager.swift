import EventKit
import SwiftUI

struct ReminderList: Identifiable {
    let id: String
    let title: String
    let color: NSColor
    let isDefault: Bool
}

@MainActor
class RemindersManager: ObservableObject {
    static let shared = RemindersManager()
    
    let eventStore = EKEventStore()
    @Published var reminders: [EKReminder] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var selectedListIdentifier: String?
    @Published var availableLists: [ReminderList] = []
    
    private let cacheService = ReminderCacheService.shared
    private let listService = ReminderListService.shared
    private let operationsService = ReminderOperationsService.shared
    
    var defaultListId: String {
        get { listService.defaultListId }
        set { listService.setDefaultList(newValue) }
    }
    
    init() {
        print("RemindersManager init - defaultListId: \(listService.defaultListId), lastSelectedList: \(String(describing: listService.getLastSelectedList()))")
        // Clear any existing selection to ensure proper initialization
        selectedListIdentifier = nil
        // Initialize cache service with event store
        cacheService.setEventStore(eventStore)
        Task {
            await requestAccess()
        }
    }
    
    func requestAccess() async {
        authorizationStatus = await operationsService.requestAccess(to: eventStore)
        if #available(macOS 14.0, *) {
            if authorizationStatus == .authorized || authorizationStatus == .fullAccess {
                await fetchLists()
                await fetchReminders()
            }
        } else {
            if authorizationStatus == .authorized {
                await fetchLists()
                await fetchReminders()
            }
        }
    }
    
    func fetchLists() async {
        print("Fetching lists - defaultListId: \(listService.defaultListId)")
        availableLists = listService.fetchLists(from: eventStore)
        
        // Initialize default list if needed
        if selectedListIdentifier == nil {
            selectedListIdentifier = listService.initializeDefaultList(from: availableLists)
        }
        
        // Save the selected list for next launch
        listService.setLastSelectedList(selectedListIdentifier)
        
        print("Available lists: \(availableLists.map { "\($0.title) (id: \($0.id), isDefault: \($0.id == listService.defaultListId))" }.joined(separator: ", "))")
    }
    
    func fetchReminders() async {
        guard let selectedList = selectedListIdentifier else {
            reminders = []
            return
        }
        
        reminders = await cacheService.fetchRemindersForList(selectedList, in: eventStore)
    }
    
    func selectList(_ identifier: String) {
        selectedListIdentifier = identifier
        listService.setLastSelectedList(identifier)
        Task {
            await fetchReminders()
        }
    }
    
    func toggleCompletion(for reminder: EKReminder) {
        do {
            try operationsService.toggleCompletion(for: reminder, in: eventStore)
            Task {
                await fetchReminders()
            }
        } catch {
            print("Failed to toggle completion: \(error)")
        }
    }
    
    func generateDeepLink(for reminder: EKReminder) -> String {
        return operationsService.generateDeepLink(for: reminder)
    }
    
    func copyRichTextLink(for reminder: EKReminder) {
        operationsService.copyRichTextLink(for: reminder)
    }
    
    func createReminder(withTitle title: String) async throws {
        guard let selectedList = selectedListIdentifier,
              let calendar = listService.getCalendar(with: selectedList, from: eventStore) else {
            return
        }
        
        _ = try operationsService.createReminder(withTitle: title, in: calendar, using: eventStore)
        await fetchReminders()
    }
    
    func setDefaultList(_ identifier: String) {
        listService.setDefaultList(identifier)
        objectWillChange.send()
    }
    
    func getDefaultCalendar() -> EKCalendar? {
        let defaultId = listService.defaultListId
        if !defaultId.isEmpty,
           let calendar = eventStore.calendar(withIdentifier: defaultId) {
            return calendar
        }
        return eventStore.defaultCalendarForNewReminders()
    }
}
