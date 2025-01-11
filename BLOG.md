# Setting Up a Modern macOS App Project with Swift Package Manager

Creating a well-structured macOS application requires careful planning and organization. In this guide, I'll walk you through setting up a macOS app project using Swift Package Manager (SPM), based on our experience building a Reminders app.

## Project Structure

Here's the ideal structure for a modern macOS app:

```
YourApp/
├── Package.swift           # Swift package manifest
├── README.md              # Project documentation
├── .gitignore             # Git ignore file
└── Sources/
    └── YourApp/          # Main app module
        ├── main.swift            # App entry point
        ├── AppDelegate.swift     # App lifecycle management
        ├── Models/              # Data models
        │   └── ...
        ├── Views/              # SwiftUI views
        │   ├── ContentView.swift
        │   └── ...
        ├── ViewModels/         # View models (if using MVVM)
        │   └── ...
        └── Managers/           # Service/business logic
            └── ...
```

## Essential Files

### 1. Package.swift
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .macOS(.v14)  // Specify minimum macOS version
    ],
    products: [
        .executable(
            name: "YourApp",
            targets: ["YourApp"]
        )
    ],
    dependencies: [
        // Add external dependencies here
    ],
    targets: [
        .executableTarget(
            name: "YourApp",
            path: "Sources/YourApp"
        )
    ]
)
```

### 2. main.swift
This is the entry point of your application:
```swift
import AppKit

// Create the application and delegate
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Run the application
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
```

### 3. AppDelegate.swift
Handles application lifecycle:
```swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu
        setupMenu()
        
        // Create window
        setupMainWindow()
        
        // Bring app to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func setupMenu() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu
        
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "Quit", 
                       action: #selector(NSApplication.terminate(_:)), 
                       keyEquivalent: "q")
    }
    
    private func setupMainWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        let contentView = NSHostingView(rootView: ContentView())
        window.contentView = contentView
        window.title = "Your App"
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
```

### 4. ContentView.swift
Your main SwiftUI view:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            // Your app's main content
            Text("Hello, macOS!")
        }
    }
}
```

## Must-Have Components

1. **Window Management**
   - Proper window creation and lifecycle management in AppDelegate
   - Window size constraints if needed
   - Window state restoration

2. **Menu Bar**
   - Basic app menu with Quit option
   - Custom menus for app functionality
   - Keyboard shortcuts

3. **Error Handling**
   - Proper error types
   - User-friendly error messages
   - Error recovery suggestions

4. **State Management**
   - Clear data flow architecture (MVVM recommended)
   - Proper use of SwiftUI property wrappers
   - State restoration

5. **Resource Management**
   - Asset catalogs for images
   - Localization setup
   - Proper cleanup in deinit

## Development Best Practices

1. **Project Organization**
   - Use clear folder structure
   - Separate concerns (Models, Views, ViewModels)
   - Keep files focused and single-purpose

2. **Git Setup**
```gitignore
.DS_Store
/.build
/Packages
xcuserdata/
DerivedData/
.swiftpm/
```

3. **Documentation**
   - README with setup instructions
   - Code documentation using /// comments
   - Architecture decisions documentation

4. **Testing Setup**
   - Unit tests for business logic
   - UI tests for critical paths
   - Test targets in Package.swift

## Common Pitfalls to Avoid

1. **Window Management**
   - Not handling window closure properly
   - Missing window size constraints
   - Improper view hierarchy

2. **Memory Management**
   - Retain cycles in closures
   - Not cleaning up observers
   - Memory leaks in view models

3. **UI/UX**
   - Not following macOS Human Interface Guidelines
   - Inconsistent keyboard shortcuts
   - Missing accessibility support

## Conclusion

A well-structured macOS app project sets the foundation for maintainable and scalable development. This structure has proven effective in our Reminders app and can be adapted for various macOS applications.

Remember to:
- Keep your structure clean and organized
- Follow macOS conventions and guidelines
- Plan for scalability from the start
- Document your setup decisions

## Resources

- [Apple's macOS Development Documentation](https://developer.apple.com/documentation/macos)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [Swift Package Manager Documentation](https://www.swift.org/package-manager/)
