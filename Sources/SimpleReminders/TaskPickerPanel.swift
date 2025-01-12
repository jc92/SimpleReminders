import AppKit
import SwiftUI

class TaskPickerPanel: NSPanel {
    static let shared = TaskPickerPanel()
    private var contentViewModel: TaskPickerViewModel
    private var localMonitor: Any?
    
    init() {
        // Initialize the view model first
        self.contentViewModel = TaskPickerViewModel()
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.nonactivatingPanel, .titled, .resizable, .closable],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.standardWindowButton(.closeButton)?.isHidden = true
        
        // Create and set the content view
        let contentView = TaskPickerView(viewModel: contentViewModel)
        self.contentView = NSHostingView(rootView: contentView)
        
        // Center on screen
        if let screenFrame = NSScreen.main?.visibleFrame {
            self.setFrameOrigin(NSPoint(
                x: screenFrame.midX - self.frame.width / 2,
                y: screenFrame.midY - self.frame.height / 2
            ))
        }
        
        // Monitor keyboard events
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self else { return event }
            
            switch event.keyCode {
            case 53: // Escape
                self.close()
                return nil
            case 36: // Return
                self.contentViewModel.confirmSelection()
                if !self.contentViewModel.isShowingLists {
                    self.close()
                }
                return nil
            case 126: // Up Arrow
                self.contentViewModel.moveSelection(up: true)
                return nil
            case 125: // Down Arrow
                self.contentViewModel.moveSelection(up: false)
                return nil
            default:
                break
            }
            
            return event
        }
    }
    
    deinit {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    func show() {
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)
        
        // Reset view model state when showing
        contentViewModel.searchText = ""
        contentViewModel.selectedIndex = 0
        contentViewModel.isShowingLists = false
    }
    
    override func close() {
        super.close()
        
        // Reset the view model state
        contentViewModel.searchText = ""
        contentViewModel.selectedIndex = 0
        contentViewModel.isShowingLists = false
    }
}
