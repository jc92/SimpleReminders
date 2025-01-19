import Foundation
import EventKit
import SwiftUI

@MainActor
class ReminderListService {
    static let shared = ReminderListService()
    
    @AppStorage("lastSelectedList") private var lastSelectedList: String?
    @AppStorage("defaultListId") private(set) var defaultListId: String = ""
    
    private init() {}
    
    func fetchLists(from eventStore: EKEventStore) -> [ReminderList] {
        let lists = eventStore.calendars(for: .reminder).map { calendar in
            ReminderList(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                color: calendar.color,
                isDefault: calendar.calendarIdentifier == defaultListId
            )
        }.sorted { list1, list2 in
            // Put Inbox first
            if list1.title == "Inbox" { return true }
            if list2.title == "Inbox" { return false }
            // Then sort alphabetically
            return list1.title.localizedCompare(list2.title) == .orderedAscending
        }
        
        return lists
    }
    
    func initializeDefaultList(from lists: [ReminderList]) -> String? {
        // Always try to find Inbox
        let inboxList = lists.first(where: { $0.title == "Inbox" })
        
        // If this is first launch (no default set) or if default list doesn't exist anymore
        if defaultListId.isEmpty || !lists.contains(where: { $0.id == defaultListId }) {
            if let inbox = inboxList {
                defaultListId = inbox.id
                return inbox.id
            }
        }
        
        // If we still don't have a selection, use Inbox or first available
        return inboxList?.id ?? lists.first?.id
    }
    
    func setDefaultList(_ listId: String) {
        defaultListId = listId
    }
    
    func getLastSelectedList() -> String? {
        return lastSelectedList
    }
    
    func setLastSelectedList(_ listId: String?) {
        lastSelectedList = listId
    }
    
    func getCalendar(with identifier: String, from eventStore: EKEventStore) -> EKCalendar? {
        return eventStore.calendar(withIdentifier: identifier)
    }
}
