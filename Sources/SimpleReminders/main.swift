import AppKit
import SwiftUI

autoreleasepool {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    #if os(macOS)
    app.setActivationPolicy(.accessory)  // This makes it a menu bar app
    #endif
    app.run()
}
