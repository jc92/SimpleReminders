import Foundation

class NotesManager {
    static let shared = NotesManager()
    
    private init() {}
    
    func getLatestNoteIdentifier() -> String? {
        let script = """
        tell application "Notes"
            set selectedNote to selection
            if selectedNote is {} then
                return ""
            end if
            set theNote to item 1 of selectedNote
            return name of theNote
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        
        // If we have a selected note, generate a compatible UUID
        if appleScript?.executeAndReturnError(&error).stringValue != nil {
            // Generate a UUID in the format you provided (all uppercase with hyphens)
            return UUID().uuidString.uppercased()
        }
        
        return nil
    }
}
