import Foundation
import EventKit

@MainActor
class ReminderCacheService {
    static let shared = ReminderCacheService()
    
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
    private weak var eventStore: EKEventStore?
    
    private init() {
        setupBackgroundRefresh()
    }
    
    func setEventStore(_ store: EKEventStore) {
        self.eventStore = store
    }
    
    private func setupBackgroundRefresh() {
        backgroundRefreshTimer?.invalidate()
        backgroundRefreshTimer = Timer.scheduledTimer(withTimeInterval: cacheValidityDuration, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                if let eventStore = self?.eventStore {
                    await self?.refreshCache(eventStore: eventStore)
                }
            }
        }
    }
    
    func refreshCache(eventStore: EKEventStore) async {
        for listId in reminderCache.keys {
            _ = await fetchRemindersForList(listId, in: eventStore, forceFetch: true)
        }
    }
    
    func isCacheValid(for listId: String) -> Bool {
        guard let cache = reminderCache[listId] else { return false }
        return Date().timeIntervalSince(cache.timestamp) < cacheValidityDuration
    }
    
    func fetchRemindersForList(_ listId: String, in eventStore: EKEventStore, forceFetch: Bool = false) async -> [EKReminder] {
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
    
    func invalidateCache(for listId: String) {
        reminderCache.removeValue(forKey: listId)
    }
    
    func invalidateAllCaches() {
        reminderCache.removeAll()
    }
}
