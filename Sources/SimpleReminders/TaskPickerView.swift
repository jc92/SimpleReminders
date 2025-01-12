import SwiftUI
import EventKit
import AppKit

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
}

struct CustomTextField: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    var onEditingChanged: (Bool) -> Void = { _ in }
    var onEnterKey: () -> Bool = { false }
    
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
        
        // Add key equivalent for Command+A
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onEditingChanged: onEditingChanged, onEnterKey: onEnterKey)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        var onEditingChanged: (Bool) -> Void
        var onEnterKey: () -> Bool
        
        init(text: Binding<String>, onEditingChanged: @escaping (Bool) -> Void, onEnterKey: @escaping () -> Bool) {
            self.text = text
            self.onEditingChanged = onEditingChanged
            self.onEnterKey = onEnterKey
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                text.wrappedValue = textField.stringValue
            }
        }
        
        func controlTextDidBeginEditing(_ obj: Notification) {
            onEditingChanged(true)
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            onEditingChanged(false)
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                // Only handle Enter if we're filtering by list
                if text.wrappedValue.hasPrefix("#") {
                    return onEnterKey()
                }
            }
            return false
        }
    }
}

struct TaskPickerView: View {
    @ObservedObject var viewModel: TaskPickerViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Button(action: {
                        viewModel.isShowingListPicker.toggle()
                    }) {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.primary)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $viewModel.isShowingListPicker) {
                        VStack {
                            TextField("Search lists...", text: $viewModel.listSearchText)
                                .textFieldStyle(.roundedBorder)
                                .padding()
                            
                            listSelectionView
                        }
                        .frame(width: 300, height: 400)
                    }
                    
                    CustomTextField(
                        text: $viewModel.searchText,
                        font: .systemFont(ofSize: 24, weight: .regular),
                        onEditingChanged: { isEditing in
                            isSearchFocused = isEditing
                        },
                        onEnterKey: {
                            let result = viewModel.handleEnterKey()
                            // Force view update after filter change
                            if result {
                                viewModel.objectWillChange.send()
                            }
                            return result
                        }
                    )
                        .focused($isSearchFocused)
                        .onChange(of: viewModel.clickedLinkId) { _ in
                            dismiss()
                        }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if viewModel.searchText.hasPrefix("#") {
                    let searchTerm = String(viewModel.searchText.dropFirst()).trimmingCharacters(in: .whitespaces)
                    let filteredLists = viewModel.availableLists.filter {
                        searchTerm.isEmpty || $0.title.localizedCaseInsensitiveContains(searchTerm)
                    }
                    if !filteredLists.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filteredLists, id: \.calendarIdentifier) { calendar in
                                    HStack {
                                        Circle()
                                            .fill(Color(nsColor: calendar.color))
                                            .frame(width: 8, height: 8)
                                        Text(calendar.title)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.secondary.opacity(0.2))
                                    )
                                    .onTapGesture {
                                        viewModel.selectList(calendar)
                                        viewModel.searchText = ""
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        }
                    }
                }
                
                if let selectedListTitle = viewModel.selectedListTitle {
                    HStack {
                        Text("List: \(selectedListTitle)")
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            viewModel.clearListFilter()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
            }
            .background(Color(NSColor.textBackgroundColor))
            
            Divider()
            
            reminderListView
        }
        .frame(width: 600, height: 400)
        .onAppear {
            isSearchFocused = true
        }
    }
    
    private var reminderListView: some View {
        List(viewModel.filteredReminders, id: \.calendarItemIdentifier, selection: .constant(viewModel.selectedIndex)) { reminder in
            HStack {
                Circle()
                    .fill(Color(nsColor: reminder.calendar.color))
                    .frame(width: 12, height: 12)
                Text(reminder.title ?? "")
                Spacer()
                if let date = reminder.dueDateComponents?.date {
                    Text(date, style: .date)
                        .foregroundColor(.secondary)
                }
            }
            .listRowBackground(
                viewModel.filteredReminders.firstIndex(where: { $0.calendarItemIdentifier == reminder.calendarItemIdentifier }) == viewModel.selectedIndex
                ? Color.accentColor.opacity(0.2)
                : Color.clear
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if let index = viewModel.filteredReminders.firstIndex(where: { $0.calendarItemIdentifier == reminder.calendarItemIdentifier }) {
                    viewModel.selectedIndex = index
                    viewModel.confirmSelection()
                    dismiss()
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var listSelectionView: some View {
        List(viewModel.filteredLists, id: \.calendarIdentifier, selection: .constant(viewModel.selectedIndex)) { calendar in
            HStack {
                Circle()
                    .fill(Color(nsColor: calendar.color))
                    .frame(width: 12, height: 12)
                Text(calendar.title)
                Spacer()
                if calendar.calendarIdentifier == viewModel.selectedListId {
                    Image(systemName: "checkmark")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectList(calendar)
            }
        }
        .listStyle(.plain)
    }
}
