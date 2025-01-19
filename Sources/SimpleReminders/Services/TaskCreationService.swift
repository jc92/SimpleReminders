import Foundation
import EventKit
import AppKit

@MainActor
class TaskCreationService {
    static let shared = TaskCreationService()
    
    private init() {}
    
    func createAndPasteTask(withText text: String, in viewModel: TaskPickerViewModel) async -> Bool {
        guard let newReminder = await viewModel.createReminder() else {
            print("Failed to create reminder")
            return false
        }
        
        RemindersManager.shared.copyRichTextLink(for: newReminder)
        do {
            try await pasteLinkInNotes()
            return true
        } catch {
            print("Failed to paste link: \(error)")
            return false
        }
    }
    
    private func pasteLinkInNotes() async throws {
        try await AppleScriptService.shared.executeScript("""
            tell application "Notes"
                activate
                tell application "System Events" to keystroke "v" using command down
            end tell
            """)
    }
}
