import AppKit

// Ensure we're on the main thread
DispatchQueue.main.async {
    autoreleasepool {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)  // This makes it a menu bar app
        app.run()
    }
}
