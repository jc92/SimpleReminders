import Foundation
import AppKit

enum AppleScriptError: Error {
    case executionFailed(String)
}

@MainActor
class AppleScriptService {
    static let shared = AppleScriptService()
    
    private init() {}
    
    func executeScript(_ script: String) async throws {
        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else {
            throw AppleScriptError.executionFailed("Failed to create script object")
        }
        
        let result = scriptObject.executeAndReturnError(&error)
        if let error = error {
            throw AppleScriptError.executionFailed("Error: \(error)")
        }
        
        // Return the result if needed in the future
        _ = result
    }
}
