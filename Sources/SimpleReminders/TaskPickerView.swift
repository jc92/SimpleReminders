import SwiftUI
import EventKit

struct TaskPickerView: View {
    @ObservedObject var viewModel: TaskPickerViewModel
    @FocusState private var isSearchFocused: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search tasks...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isSearchFocused)
                    .font(.system(size: 15))
                    .frame(height: 30)
                    .onSubmit {
                        if !viewModel.filteredReminders.isEmpty {
                            viewModel.confirmSelection()
                            onDismiss()
                        }
                    }
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
            .frame(width: 400)
            .background(Color(NSColor.textBackgroundColor))
            
            // Results list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.filteredReminders.enumerated()), id: \.element.calendarItemIdentifier) { index, reminder in
                        HStack {
                            Text(reminder.title ?? "Untitled")
                                .lineLimit(1)
                                .font(.system(size: 14))
                            Spacer()
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                                .scaleEffect(viewModel.clickedLinkId == reminder.calendarItemIdentifier ? 0.7 : 1.0)
                                .animation(.spring(response: 0.2, dampingFraction: 0.5), value: viewModel.clickedLinkId)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedIndex = index
                            viewModel.confirmSelection()
                            onDismiss()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(width: 400, alignment: .leading)
                        .background(viewModel.selectedIndex == index ? Color.accentColor.opacity(0.2) : Color.clear)
                        
                        if reminder.calendarItemIdentifier != viewModel.filteredReminders.last?.calendarItemIdentifier {
                            Divider()
                                .padding(.leading, 12)
                        }
                    }
                }
            }
            .frame(width: 400, height: 450)
        }
        .frame(width: 400, height: 500)
        .onAppear {
            isSearchFocused = true
            viewModel.selectedIndex = 0
        }
        .onChange(of: viewModel.filteredReminders) { _ in
            // Reset selection when search results change
            viewModel.selectedIndex = 0
        }
        .background(
            Button("Select All") {
                NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
            }.keyboardShortcut("a", modifiers: .command)
            .opacity(0)
        )
        .background(
            Button("Copy") {
                NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
            }.keyboardShortcut("c", modifiers: .command)
            .opacity(0)
        )
        .background(
            Button("Paste") {
                NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
            }.keyboardShortcut("v", modifiers: .command)
            .opacity(0)
        )
        .background(
            Button("Cut") {
                NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
            }.keyboardShortcut("x", modifiers: .command)
            .opacity(0)
        )
    }
    
    private func copyAndDismiss(reminder: EKReminder) {
        viewModel.confirmSelection()
        
        // Dismiss after a short delay to show the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
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
