import SwiftUI
import EventKit

@MainActor
class TaskPickerViewModel: ObservableObject {
    @Published var selectedIndex = 0
    @Published var searchText = ""
    @Published var clickedLinkId: String? = nil
    
    var filteredReminders: [EKReminder] {
        let openReminders = RemindersManager.shared.reminders.filter { !$0.isCompleted }
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
