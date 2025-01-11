import AppKit

// Create the application and delegate
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)  // This makes it a menu bar app
app.run()
