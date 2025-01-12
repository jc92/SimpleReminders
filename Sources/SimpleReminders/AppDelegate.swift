import AppKit
import SwiftUI
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var keyboardMonitor: Any?
    private var hotKey: HotKey?
    private var contentView: ContentView!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Reminders")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create content view
        contentView = ContentView()
        
        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .applicationDefined
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        // Create menu
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu
        
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        // Setup global shortcut (Command + Shift + R)
        hotKey = HotKey(key: .r, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = { [weak self] in
            self?.showTaskPicker()
        }
        
        // Monitor clicks outside the popover
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            
            if self.popover.isShown {
                if let button = self.statusItem.button,
                   !button.frame.contains(button.convert(event.locationInWindow, from: nil)) {
                    self.closePopover()
                }
            }
        }
        
        // Monitor keyboard events
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            print("Key event received: \(event.keyCode)")
            
            if self.popover.isShown {
                switch event.keyCode {
                case 125: // Down Arrow
                    print("Down arrow pressed")
                    DispatchQueue.main.async {
                        self.contentView.navigateList(direction: 1)
                    }
                    return nil
                case 126: // Up Arrow
                    print("Up arrow pressed")
                    DispatchQueue.main.async {
                        self.contentView.navigateList(direction: -1)
                    }
                    return nil
                case 36: // Return
                    print("Return pressed")
                    DispatchQueue.main.async {
                        self.contentView.selectFocusedList()
                    }
                    return nil
                default:
                    return event
                }
            }
            return event
        }
    }
    
    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        if let keyboardMonitor = keyboardMonitor {
            NSEvent.removeMonitor(keyboardMonitor)
        }
    }
    
    @objc func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    func showPopover() {
        if let button = statusItem.button {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            
            // Give time for the window to appear and then set focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("Setting initial focus")
                if let window = self.popover.contentViewController?.view.window {
                    window.makeFirstResponder(nil)
                    self.contentView.focusSelectedList()
                }
            }
        }
    }
    
    func closePopover() {
        popover.performClose(nil)
    }
    
    func showTaskPicker() {
        if let currentApp = NSWorkspace.shared.frontmostApplication,
           currentApp.bundleIdentifier == "com.apple.Notes" {
            TaskPickerPanel.shared.show()
        }
    }
}
