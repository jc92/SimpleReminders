import AppKit
import SwiftUI

class TaskPickerPanel: NSPanel {
    static let shared = TaskPickerPanel()
    private var contentViewModel: TaskPickerViewModel?
    private var localMonitor: Any?
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.nonactivatingPanel, .titled, .resizable, .closable],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        let viewModel = TaskPickerViewModel()
        contentViewModel = viewModel
        let contentView = TaskPickerView(viewModel: viewModel) { [weak self] in
            self?.close()
        }
        
        self.contentViewController = NSHostingController(rootView: contentView)
        self.backgroundColor = .windowBackgroundColor
        
        // Set up local event monitor for keyboard events
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if let handled = self?.handleKeyEvent(event) {
                return handled ? nil : event
            }
            return event
        }
    }
    
    deinit {
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }
    
    func show() {
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.main?.frame ?? .zero
        
        // Position panel below the cursor
        var panelOrigin = NSPoint(
            x: mouseLocation.x - frame.width / 2,
            y: mouseLocation.y - frame.height - 10
        )
        
        // Make sure the panel stays within screen bounds
        if panelOrigin.x < 0 {
            panelOrigin.x = 0
        } else if panelOrigin.x + frame.width > screenFrame.width {
            panelOrigin.x = screenFrame.width - frame.width
        }
        
        if panelOrigin.y < 0 {
            panelOrigin.y = 0
        }
        
        setFrameOrigin(panelOrigin)
        makeKeyAndOrderFront(nil)
    }
    
    override func cancelOperation(_ sender: Any?) {
        close()
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // Handle navigation keys
        switch event.keyCode {
        case 126: // Up arrow
            contentViewModel?.moveSelection(up: true)
            return true
        case 125: // Down arrow
            contentViewModel?.moveSelection(up: false)
            return true
        case 36: // Return
            if let viewModel = contentViewModel, !viewModel.filteredReminders.isEmpty {
                viewModel.confirmSelection()
                close()
                
                // Wait a tiny bit for the window to close, then simulate paste
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.simulatePaste()
                }
            }
            return true
        case 53: // Escape
            close()
            return true
        default:
            return false
        }
    }
    
    private func simulatePaste() {
        let script = """
        tell application "Notes"
            activate
            delay 0.1
        end tell
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("Error executing AppleScript: \(error)")
            }
        }
    }
}
