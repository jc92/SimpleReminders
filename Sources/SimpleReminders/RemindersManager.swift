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
    
    private let eventStore = EKEventStore()
    @Published var reminders: [EKReminder] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @AppStorage("selectedListIdentifier") private var selectedListIdentifier: String?
    @Published var availableLists: [ReminderList] = []
    
    init() {
        Task {
            await requestAccess()
        }
    }
    
    func requestAccess() async {
        if #available(macOS 14.0, *) {
            do {
                try await eventStore.requestFullAccessToReminders()
                authorizationStatus = .fullAccess
                await fetchLists()
                await fetchReminders()
            } catch {
                print("Failed to request access: \(error)")
                authorizationStatus = .denied
            }
        } else {
            eventStore.requestAccess(to: .reminder) { [weak self] granted, error in
                Task { @MainActor in
                    self?.authorizationStatus = granted ? .authorized : .denied
                    if granted {
                        await self?.fetchLists()
                        await self?.fetchReminders()
                    }
                }
            }
        }
    }
    
    func fetchLists() async {
        availableLists = eventStore.calendars(for: .reminder).map { calendar in
            ReminderList(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                color: calendar.color,
                isDefault: calendar.calendarIdentifier == selectedListIdentifier
            )
        }
        if selectedListIdentifier == nil {
            selectedListIdentifier = availableLists.first?.id
        }
    }
    
    func fetchReminders() async {
        let calendar = eventStore.calendars(for: .reminder).first { $0.calendarIdentifier == selectedListIdentifier }
        let predicate = eventStore.predicateForReminders(in: [calendar].compactMap { $0 })
        
        let reminders = await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
        
        self.reminders = reminders.sorted { reminder1, reminder2 in
            switch (reminder1.dueDateComponents?.date, reminder2.dueDateComponents?.date) {
            case (.some(let date1), .some(let date2)):
                return date1 < date2
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return reminder1.title?.localizedCompare(reminder2.title ?? "") == .orderedAscending
            }
        }
    }
    
    func selectList(_ identifier: String) {
        selectedListIdentifier = identifier
        Task {
            await fetchReminders()
        }
    }
    
    func toggleCompletion(for reminder: EKReminder) {
        reminder.isCompleted = !reminder.isCompleted
        try? eventStore.save(reminder, commit: true)
        Task {
            await fetchReminders()
        }
    }
}
