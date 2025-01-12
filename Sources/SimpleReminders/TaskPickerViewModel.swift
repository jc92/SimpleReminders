import SwiftUI
import EventKit
import CoreGraphics
import AppKit

@MainActor
class TaskPickerViewModel: ObservableObject {
    @Published var selectedIndex = 0
    @Published var searchText = ""
    @Published var clickedLinkId: String? = nil
    @Published var isShowingListPicker = false
    @Published var selectedListId: String? = nil
    @Published var selectedListTitle: String? = nil
    @Published var listSearchText = ""
    
    private var allReminders: [EKReminder] = []
    private var availableLists: [EKCalendar] = []
    
    init() {
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
        }
    }
    
    var filteredReminders: [EKReminder] {
        let openReminders = allReminders.filter { !$0.isCompleted }
        if searchText.isEmpty {
            return openReminders
        }
        
        return openReminders.filter { reminder in
            reminder.title?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var filteredLists: [EKCalendar] {
        if listSearchText.isEmpty {
            return availableLists
        }
        return availableLists.filter { calendar in
            calendar.title.localizedCaseInsensitiveContains(listSearchText)
        }
    }
    
    func selectList(_ calendar: EKCalendar) {
        selectedListId = calendar.calendarIdentifier
        selectedListTitle = calendar.title
        isShowingListPicker = false
        listSearchText = ""
        
        // Immediately filter existing reminders
        allReminders = allReminders.filter { reminder in
            reminder.calendar.calendarIdentifier == calendar.calendarIdentifier
        }
        
        // Then fetch fresh data in the background
        Task {
            await fetchAllReminders()
        }
    }
    
    func clearListFilter() {
        selectedListId = nil
        selectedListTitle = nil
        
        // Immediately show all reminders from all calendars
        let eventStore = RemindersManager.shared.eventStore
        let calendars = eventStore.calendars(for: .reminder)
        let predicate = eventStore.predicateForReminders(in: calendars)
        
        // Use existing reminders from all calendars immediately
        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            guard let self = self else { return }
            Task { @MainActor in
                self.allReminders = (reminders ?? []).sorted { reminder1, reminder2 in
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
            }
        }
        
        // Then fetch fresh data in the background
        Task {
            await fetchAllReminders()
        }
    }
    
    func moveSelection(up: Bool) {
        if isShowingListPicker {
            let count = filteredLists.count
            if count == 0 { return }
            selectedIndex = (selectedIndex + (up ? -1 : 1) + count) % count
        } else {
            let count = filteredReminders.count
            if count == 0 { return }
            selectedIndex = (selectedIndex + (up ? -1 : 1) + count) % count
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
}
