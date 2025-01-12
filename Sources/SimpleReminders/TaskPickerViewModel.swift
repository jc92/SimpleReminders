import SwiftUI
import EventKit

@MainActor
class TaskPickerViewModel: ObservableObject {
    @Published var selectedIndex = 0
    @Published var searchText = ""
    @Published var clickedLinkId: String? = nil
    @Published var isShowingLists = false
    @Published var selectedListId: String? = nil
    @Published var selectedListTitle: String? = nil
    
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
        
        // If search text starts with #, show lists instead
        if searchText.hasPrefix("#") {
            isShowingLists = true
            return []
        }
        
        return openReminders.filter { reminder in
            reminder.title?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var filteredLists: [EKCalendar] {
        let searchTerm = searchText.dropFirst() // Remove the # prefix
        if searchTerm.isEmpty {
            return availableLists
        }
        return availableLists.filter { calendar in
            calendar.title.localizedCaseInsensitiveContains(String(searchTerm))
        }
    }
    
    func selectList(_ calendar: EKCalendar) {
        selectedListId = calendar.calendarIdentifier
        selectedListTitle = calendar.title
        searchText = ""
        isShowingLists = false
        Task {
            await fetchAllReminders()
        }
    }
    
    func clearListFilter() {
        selectedListId = nil
        selectedListTitle = nil
        Task {
            await fetchAllReminders()
        }
    }
    
    func moveSelection(up: Bool) {
        if isShowingLists {
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
        if isShowingLists {
            guard !filteredLists.isEmpty else { return }
            let selectedList = filteredLists[selectedIndex]
            selectList(selectedList)
        } else {
            guard !filteredReminders.isEmpty else { return }
            let reminder = filteredReminders[selectedIndex]
            clickedLinkId = reminder.calendarItemIdentifier
            RemindersManager.shared.copyRichTextLink(for: reminder)
        }
    }
}
