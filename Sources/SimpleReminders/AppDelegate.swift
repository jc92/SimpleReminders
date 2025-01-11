import AppKit
import SwiftUI
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var hotKey: HotKey?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Reminders")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .applicationDefined
        popover.contentViewController = NSHostingController(rootView: ContentView())
        
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
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
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
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            if let window = popover.contentViewController?.view.window {
                window.level = .popUpMenu
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
