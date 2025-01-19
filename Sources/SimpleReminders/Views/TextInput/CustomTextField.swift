import SwiftUI
import AppKit

class TextFieldCoordinator: NSObject, NSTextFieldDelegate {
    var text: Binding<String>
    var onEditingChanged: (Bool) -> Void
    var onEnterKey: () -> Bool
    var onArrowUp: () -> Void
    var onArrowDown: () -> Void
    weak var viewModel: TaskPickerViewModel?
    
    init(text: Binding<String>, 
         onEditingChanged: @escaping (Bool) -> Void, 
         onEnterKey: @escaping () -> Bool,
         onArrowUp: @escaping () -> Void,
         onArrowDown: @escaping () -> Void,
         viewModel: TaskPickerViewModel) {
        self.text = text
        self.onEditingChanged = onEditingChanged
        self.onEnterKey = onEnterKey
        self.onArrowUp = onArrowUp
        self.onArrowDown = onArrowDown
        self.viewModel = viewModel
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            text.wrappedValue = textField.stringValue
            viewModel?.updateSearchText(textField.stringValue)
        }
    }
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        onEditingChanged(true)
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        onEditingChanged(false)
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.insertNewline(_:)):
            return onEnterKey()
        case #selector(NSResponder.moveUp(_:)):
            onArrowUp()
            return true
        case #selector(NSResponder.moveDown(_:)):
            onArrowDown()
            return true
        default:
            return false
        }
    }
}

class CustomNSTextField: NSTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "a":
                if let editor = currentEditor() {
                    editor.selectAll(nil)
                    return true
                }
            case "c":
                if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) {
                    return true
                }
            case "v":
                if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) {
                    return true
                }
            case "x":
                if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) {
                    return true
                }
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 125: // Down arrow
            if let onArrowDown = (delegate as? TextFieldCoordinator)?.onArrowDown {
                onArrowDown()
            } else {
                super.keyDown(with: event)
            }
        case 126: // Up arrow
            if let onArrowUp = (delegate as? TextFieldCoordinator)?.onArrowUp {
                onArrowUp()
            } else {
                super.keyDown(with: event)
            }
        default:
            super.keyDown(with: event)
        }
    }
}

struct CustomTextField: NSViewRepresentable {
    typealias NSViewType = CustomNSTextField
    typealias Coordinator = TextFieldCoordinator
    
    @Binding var text: String
    var font: NSFont
    var onEditingChanged: (Bool) -> Void = { _ in }
    var onEnterKey: () -> Bool = { false }
    var onArrowUp: () -> Void = { }
    var onArrowDown: () -> Void = { }
    var viewModel: TaskPickerViewModel
    
    func makeNSView(context: Context) -> CustomNSTextField {
        let textField = CustomNSTextField()
        textField.delegate = context.coordinator
        textField.font = font
        textField.placeholderString = "Search reminders... (# for lists)"
        textField.focusRingType = .none
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.cell?.isScrollable = true
        textField.cell?.wraps = false
        textField.cell?.usesSingleLineMode = true
        
        let menu = NSMenu()
        let selectAllItem = NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        selectAllItem.keyEquivalentModifierMask = .command
        menu.addItem(selectAllItem)
        textField.menu = menu
        
        return textField
    }
    
    func updateNSView(_ nsView: CustomNSTextField, context: Context) {
        nsView.stringValue = text
    }
    
    func makeCoordinator() -> TextFieldCoordinator {
        TextFieldCoordinator(
            text: $text,
            onEditingChanged: onEditingChanged,
            onEnterKey: onEnterKey,
            onArrowUp: onArrowUp,
            onArrowDown: onArrowDown,
            viewModel: viewModel
        )
    }
}
