import Foundation
import EventKit
import AppKit

@MainActor
class ReminderOperationsService {
    static let shared = ReminderOperationsService()
    
    private init() {}
    
    func requestAccess(to eventStore: EKEventStore) async -> EKAuthorizationStatus {
        if #available(macOS 14.0, *) {
            do {
                try await eventStore.requestFullAccessToReminders()
                return .fullAccess
            } catch {
                print("Failed to request access: \(error)")
                return .denied
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .reminder) { granted, error in
                    continuation.resume(returning: granted ? .authorized : .denied)
                }
            }
        }
    }
    
    func toggleCompletion(for reminder: EKReminder, in eventStore: EKEventStore) throws {
        reminder.isCompleted = !reminder.isCompleted
        try eventStore.save(reminder, commit: true)
    }
    
    func createReminder(withTitle title: String, in calendar: EKCalendar, using eventStore: EKEventStore) throws -> EKReminder {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = calendar
        try eventStore.save(reminder, commit: true)
        return reminder
    }
    
    func generateDeepLink(for reminder: EKReminder) -> String {
        guard let uuid = reminder.calendarItemExternalIdentifier else { return "" }
        return "x-apple-reminderkit://REMCDReminder/\(uuid)"
    }
    
    func copyRichTextLink(for reminder: EKReminder) {
        let link = generateDeepLink(for: reminder)
        let attributedString = NSAttributedString(
            string: reminder.title ?? "Untitled Reminder",
            attributes: [.link: link]
        )
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([attributedString])
    }
}
