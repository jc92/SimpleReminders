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
    
    // Persist selected list
    @AppStorage("lastSelectedList") private var lastSelectedList: String?
    
    init() {
        // Restore last selected list
        selectedListIdentifier = lastSelectedList
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
        guard let selectedList = selectedListIdentifier else {
            reminders = []
            return
        }

        let predicate = eventStore.predicateForReminders(in: [eventStore.calendar(withIdentifier: selectedList)!])
        
        let fetchedReminders = await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
        
        await MainActor.run {
            self.reminders = fetchedReminders.sorted { reminder1, reminder2 in
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
    
    func selectList(_ identifier: String) {
        selectedListIdentifier = identifier
        lastSelectedList = identifier  // Persist selection
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
    
    func generateDeepLink(for reminder: EKReminder) -> String {
        guard let uuid = reminder.calendarItemExternalIdentifier else { return "" }
        return "x-apple-reminderkit://REMCDReminder/\(uuid)"
    }
    
    func copyToClipboard(_ string: String) {
        guard !string.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
    
    func copyRichTextLink(for reminder: EKReminder) {
        guard let url = generateDeepLink(for: reminder).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let title = reminder.title else { return }
        
        // Create an attributed string with the link
        let attributedString = NSAttributedString(
            string: title,
            attributes: [
                .link: url,
                .foregroundColor: NSColor.linkColor
            ]
        )
        
        // Convert to RTF data
        let rtfData = try? attributedString.rtf(from: NSRange(location: 0, length: attributedString.length),
                                              documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        
        // Copy both RTF and plain text to support different paste targets
        NSPasteboard.general.clearContents()
        if let rtfData = rtfData {
            NSPasteboard.general.setData(rtfData, forType: .rtf)
        }
        NSPasteboard.general.setString(title, forType: .string)
    }
}
