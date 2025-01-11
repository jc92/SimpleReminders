import SwiftUI
import EventKit

@MainActor
class TaskPickerViewModel: ObservableObject {
    @Published var selectedIndex = 0
    @Published var searchText = ""
    @Published var clickedLinkId: String? = nil
    private var allReminders: [EKReminder] = []
    
    init() {
        Task {
            await fetchAllReminders()
        }
    }
    
    func fetchAllReminders() async {
        let eventStore = RemindersManager.shared.eventStore
        let calendars = eventStore.calendars(for: .reminder)
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
                    return reminder1.title?.localizedCompare(reminder2.title ?? "") == .orderedAscending
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
    
    func moveSelection(up: Bool) {
        if filteredReminders.isEmpty { return }
        
        if up {
            selectedIndex = selectedIndex > 0 ? selectedIndex - 1 : filteredReminders.count - 1
        } else {
            selectedIndex = selectedIndex < filteredReminders.count - 1 ? selectedIndex + 1 : 0
        }
    }
    
    func confirmSelection() {
        guard !filteredReminders.isEmpty else { return }
        let reminder = filteredReminders[selectedIndex]
        clickedLinkId = reminder.calendarItemIdentifier
        RemindersManager.shared.copyRichTextLink(for: reminder)
    }
}
