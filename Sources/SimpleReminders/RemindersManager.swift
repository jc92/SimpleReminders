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
    
    // Cache structure for reminders
    private struct ReminderCache {
        let reminders: [EKReminder]
        let timestamp: Date
        let listId: String
    }
    
    // Cache-related properties
    private var reminderCache: [String: ReminderCache] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    private var backgroundRefreshTimer: Timer?
    
    // Persist selected list
    @AppStorage("lastSelectedList") private var lastSelectedList: String?
    
    init() {
        // Restore last selected list
        selectedListIdentifier = lastSelectedList
        Task {
            await requestAccess()
        }
        setupBackgroundRefresh()
    }
    
    private func setupBackgroundRefresh() {
        backgroundRefreshTimer?.invalidate()
        backgroundRefreshTimer = Timer.scheduledTimer(withTimeInterval: cacheValidityDuration, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshCache()
            }
        }
    }
    
    private func refreshCache() async {
        for listId in reminderCache.keys {
            await fetchRemindersForList(listId, forceFetch: true)
        }
    }
    
    private func isCacheValid(for listId: String) -> Bool {
        guard let cache = reminderCache[listId] else { return false }
        return Date().timeIntervalSince(cache.timestamp) < cacheValidityDuration
    }
    
    private func fetchRemindersForList(_ listId: String, forceFetch: Bool = false) async -> [EKReminder] {
        if !forceFetch && isCacheValid(for: listId) {
            return reminderCache[listId]?.reminders ?? []
        }
        
        guard let calendar = eventStore.calendar(withIdentifier: listId) else { return [] }
        let predicate = eventStore.predicateForReminders(in: [calendar])
        
        let fetchedReminders = await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
        
        let sortedReminders = fetchedReminders.sorted { reminder1, reminder2 in
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
        
        // Update cache
        reminderCache[listId] = ReminderCache(
            reminders: sortedReminders,
            timestamp: Date(),
            listId: listId
        )
        
        return sortedReminders
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

        let fetchedReminders = await fetchRemindersForList(selectedList)
        await MainActor.run {
            self.reminders = fetchedReminders
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
