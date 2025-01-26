// Set the deployment target to macOS 14
import SwiftUI
import AppKit

autoreleasepool {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)  // This makes it a menu bar app
    app.run()
}
