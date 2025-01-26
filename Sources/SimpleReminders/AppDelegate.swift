import AppKit
import SwiftUI
import HotKey
import EventKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var keyboardMonitor: Any?
    private var hotKey: HotKey?
    private var contentView: ContentView!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create content view
        contentView = ContentView()
        
        // Request Reminders access immediately
        if #available(macOS 10.15, *) {
            Task {
                await RemindersManager.shared.requestAccess()
            }
        } else {
            // Handle the case for older macOS versions
            // You might want to set a default view or show an alert
        }
        
        // Create the status item
        if #available(macOS 11.0, *) {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        } else {
            statusItem = NSStatusBar.system.statusItem(withLength: 24)
        }
        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                if let image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Reminders") {
                    image.isTemplate = true  // This ensures proper dark/light mode support
                    button.image = image
                }
            } else {
                // Fallback for older macOS versions
                if let image = NSImage(named: NSImage.actionTemplateName) {
                    image.isTemplate = true
                    button.image = image
                }
            }
            button.action = #selector(togglePopover)
            button.target = self
            button.imagePosition = .imageLeft
        }
        
        // Create popover
        popover = NSPopover()
        if #available(macOS 11.0, *) {
            popover.contentSize = NSSize(width: 400, height: 500)
            popover.behavior = .transient  // Changed to transient for better behavior
        } else {
            popover.contentSize = NSSize(width: 400, height: 500)
            popover.behavior = .applicationDefined
        }
        if #available(macOS 11.0, *) {
            popover.contentViewController = NSHostingController(
                rootView: contentView.environmentObject(RemindersManager.shared)
            )
        } else {
            // Handle the case for older macOS versions
            // You might want to set a default view or show an alert
        }
        
        // Create menu
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu
        
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        
        // Add menu items
        appMenu.addItem(withTitle: "About SimpleReminders", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Preferences...", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        // Setup global shortcut (Command + Shift + R)
        if #available(macOS 10.12, *) {
            hotKey = HotKey(key: .r, modifiers: [.command, .shift])
            hotKey?.keyDownHandler = { [weak self] in
                NSApp.activate(ignoringOtherApps: true)
                TaskPickerPanel.shared.makeKeyAndOrderFront(nil)
                TaskPickerPanel.shared.center()
            }
        } else {
            // Handle the case for older macOS versions
            // You might want to set a default view or show an alert
        }
        
        // Monitor clicks outside the popover
        if #available(macOS 10.12, *) {
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                guard let self = self else { return }
                
                if self.popover.isShown {
                    if let button = self.statusItem.button,
                       !button.frame.contains(button.convert(event.locationInWindow, from: nil)) {
                        self.closePopover()
                    }
                }
            }
        } else {
            // Handle the case for older macOS versions
            // You might want to set a default view or show an alert
        }
        
        // Monitor keyboard events
        if #available(macOS 10.12, *) {
            keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self else { return event }
                
                if self.popover.isShown {
                    switch event.keyCode {
                    case 125: // Down Arrow
                        DispatchQueue.main.async {
                            self.contentView.navigateList(direction: 1)
                        }
                        return nil
                    case 126: // Up Arrow
                        DispatchQueue.main.async {
                            self.contentView.navigateList(direction: -1)
                        }
                        return nil
                    case 36: // Return
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
        } else {
            // Handle the case for older macOS versions
            // You might want to set a default view or show an alert
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
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
        TaskPickerPanel.shared.show()
    }
}
