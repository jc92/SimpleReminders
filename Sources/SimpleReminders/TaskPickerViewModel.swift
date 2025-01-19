import SwiftUI
import EventKit
import CoreGraphics
import AppKit

@MainActor
class TaskPickerViewModel: ObservableObject {
    @Published var selectedIndex = 0
    @Published var searchText = ""
    @Published var pendingListFilter = false
    @Published var clickedLinkId: String? = nil
    @Published var isShowingListPicker = false
    @Published var selectedListId: String? = nil
    @Published var selectedListTitle: String? = nil
    @Published var listSearchText = ""
    
    private var allReminders: [EKReminder] = []
    @Published var availableLists: [EKCalendar] = []
    
    init() {
        // Initialize with the default list from RemindersManager
        let remindersManager = RemindersManager.shared
        if !remindersManager.defaultListId.isEmpty {
            selectedListId = remindersManager.defaultListId
            if let calendar = remindersManager.eventStore.calendar(withIdentifier: remindersManager.defaultListId) {
                selectedListTitle = calendar.title
            }
        }
        
        Task {
            await fetchAllReminders()
            await fetchAvailableLists()
        }
    }
    
    func fetchAvailableLists() async {
        let eventStore = RemindersManager.shared.eventStore
        await MainActor.run {
            self.availableLists = eventStore.calendars(for: .reminder)
        }
    }
    
    func fetchAllReminders() async {
        let eventStore = RemindersManager.shared.eventStore
        let calendars: [EKCalendar]
        if let selectedListId = selectedListId,
           let calendar = eventStore.calendar(withIdentifier: selectedListId) {
            calendars = [calendar]
        } else {
            calendars = eventStore.calendars(for: .reminder)
        }
        let predicate = eventStore.predicateForReminders(in: calendars)
        
        let fetchedReminders = await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
        
        await MainActor.run {
            self.allReminders = fetchedReminders.sorted { reminder1, reminder2 in
                switch (reminder1.dueDateComponents?.date, reminder2.dueDateComponents?.date) {
                case (.some(let date1), .some(let date2)):
                    return date1 < date2
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return (reminder1.title ?? "") < (reminder2.title ?? "")
                }
            }
            // Reset selection if it's invalid
            validateAndUpdateSelection()
        }
    }
    
    public func validateAndUpdateSelection() {
        let filteredCount = filteredReminders.count
        if filteredCount == 0 {
            selectedIndex = 0
        } else if selectedIndex >= filteredCount {
            selectedIndex = filteredCount - 1
        }
    }
    
    var filteredReminders: [EKReminder] {
        let openReminders = allReminders.filter { !$0.isCompleted }
        
        // If there's a pending list filter, apply it
        let filteredByList = selectedListId == nil ? openReminders :
            openReminders.filter { $0.calendar.calendarIdentifier == selectedListId }
        
        // Then apply text search if not in list filter mode
        if searchText.isEmpty || (searchText.hasPrefix("#") && !pendingListFilter) {
            return filteredByList
        }
        
        return filteredByList.filter { reminder in
            reminder.title?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    func selectList(_ calendar: EKCalendar) {
        selectedListId = calendar.calendarIdentifier
        selectedListTitle = calendar.title
        Task {
            await fetchAllReminders()
            // Force a UI update
            objectWillChange.send()
        }
    }
    
    func clearListFilter() {
        selectedListId = nil
        selectedListTitle = nil
        Task {
            await fetchAllReminders()
            // Force a UI update
            objectWillChange.send()
        }
    }
    
    func handleEnterKey() -> Bool {
        if searchText.hasPrefix("#") {
            let searchTerm = String(searchText.dropFirst()).trimmingCharacters(in: .whitespaces)
            pendingListFilter = true
            if !searchTerm.isEmpty {
                // Try to find a matching list
                if let matchingList = availableLists.first(where: { $0.title.localizedCaseInsensitiveContains(searchTerm) }) {
                    selectList(matchingList)
                    // Clear the search text after applying filter
                    searchText = ""
                }
            } else {
                // If only # is typed, show all lists
                clearListFilter()
                // Clear the search text after clearing filter
                searchText = ""
            }
            return true // Handled the Enter key
        }
        
        // Create a new reminder if no existing reminders match the search and no # prefix
        if filteredReminders.isEmpty && !searchText.hasPrefix("#") {
            Task {
                await createReminder()
            }
            return true
        }
        return false // Not handled, let the normal reminder creation flow proceed
    }
    
    func moveSelection(up: Bool) {
        if isShowingListPicker {
            let count = filteredLists.count
            if count == 0 { return }
            selectedIndex = (selectedIndex + (up ? -1 : 1) + count) % count
            
            // Update selected list when navigating
            let selectedList = filteredLists[selectedIndex]
            selectedListId = selectedList.calendarIdentifier
            selectedListTitle = selectedList.title
            Task {
                await fetchAllReminders()
                objectWillChange.send()
            }
        } else {
            let count = filteredReminders.count
            if count == 0 { return }
            selectedIndex = (selectedIndex + (up ? -1 : 1) + count) % count
        }
    }
    
    func moveSelectionUp() {
        if !filteredReminders.isEmpty {
            if selectedIndex > 0 {
                selectedIndex -= 1
            } else {
                selectedIndex = filteredReminders.count - 1
            }
        }
    }
    
    func moveSelectionDown() {
        if !filteredReminders.isEmpty {
            if selectedIndex < filteredReminders.count - 1 {
                selectedIndex += 1
            } else {
                selectedIndex = 0
            }
        }
    }
    
    func selectPreviousItem() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        } else if !filteredReminders.isEmpty {
            selectedIndex = filteredReminders.count - 1
        }
    }
    
    func selectNextItem() {
        if selectedIndex < filteredReminders.count - 1 {
            selectedIndex += 1
        } else {
            selectedIndex = 0
        }
    }
    
    func confirmSelection() {
        if isShowingListPicker {
            guard !filteredLists.isEmpty else { return }
            let selectedList = filteredLists[selectedIndex]
            selectList(selectedList)
        } else {
            guard !filteredReminders.isEmpty else { return }
            let reminder = filteredReminders[selectedIndex]
            clickedLinkId = reminder.calendarItemIdentifier
            RemindersManager.shared.copyRichTextLink(for: reminder)
            
            // Find Notes app
            if let notesApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.Notes" }) {
                // Activate Notes app and wait a bit for it to focus
                notesApp.activate(options: .activateIgnoringOtherApps)
                
                // Wait for a short moment to ensure Notes is active and focused
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Simulate Command+V
                    let source = CGEventSource(stateID: .combinedSessionState)
                    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)  // 'v' key
                    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
                    
                    keyDown?.flags = .maskCommand
                    keyUp?.flags = .maskCommand
                    
                    keyDown?.post(tap: .cgAnnotatedSessionEventTap)
                    keyUp?.post(tap: .cgAnnotatedSessionEventTap)
                }
            }
        }
    }
    
    func createReminder() async -> EKReminder? {
        guard !searchText.isEmpty else { return nil }
        
        let eventStore = RemindersManager.shared.eventStore
        // Use selected list if set, otherwise use default list
        let calendar = selectedListId.flatMap { eventStore.calendar(withIdentifier: $0) } 
            ?? RemindersManager.shared.getDefaultCalendar()
        
        guard let calendar = calendar else {
            print("Error: No valid calendar found for reminder creation")
            return nil
        }
        
        print("Creating reminder in calendar: \(calendar.title) (id: \(calendar.calendarIdentifier))")
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = searchText
        reminder.calendar = calendar
    
        
        try? eventStore.save(reminder, commit: true)
        searchText = ""
        await fetchAllReminders()
        return reminder
    }
    
    func updateSearchText(_ newText: String) {
        searchText = newText
        validateAndUpdateSelection()
    }
    
    var filteredLists: [EKCalendar] {
        if listSearchText.isEmpty {
            return availableLists
        }
        return availableLists.filter { calendar in
            calendar.title.localizedCaseInsensitiveContains(listSearchText)
        }
    }
}
