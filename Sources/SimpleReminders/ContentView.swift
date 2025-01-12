import SwiftUI
import EventKit

class KeyboardManager: ObservableObject {
    static let shared = KeyboardManager()
    private var monitor: Any?
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?
    var onReturn: (() -> Void)?
    
    init() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            switch event.keyCode {
            case 126: // Up Arrow
                self?.onUpArrow?()
                return nil
            case 125: // Down Arrow
                self?.onDownArrow?()
                return nil
            case 36: // Return
                self?.onReturn?()
                return nil
            default:
                return event
            }
        }
    }
    
    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

class ListFocusState: ObservableObject {
    static let shared = ListFocusState()
    @Published var focusedListId: String?
    
    private init() {}
}

struct ContentView: View {
    @StateObject private var remindersManager = RemindersManager.shared
    @ObservedObject private var focusState = ListFocusState.shared
    @ObservedObject private var keyboardManager = KeyboardManager.shared
    @AppStorage("showCompleted") private var showCompleted = false
    @State private var showCopyNotification = false
    @State private var lastCopiedTitle = ""
    @State private var clickedLinkId: String? = nil
    @State private var selectedMenuIndex = 0
    @Namespace private var listNamespace
    @Environment(\.scenePhase) private var scenePhase
    
    var filteredReminders: [EKReminder] {
        remindersManager.reminders.filter { reminder in
            showCompleted || !reminder.isCompleted
        }
    }
    
    func copyDeepLink(for reminder: EKReminder) {
        let deepLink = remindersManager.generateDeepLink(for: reminder)
        remindersManager.copyToClipboard(deepLink)
        lastCopiedTitle = reminder.title ?? "Untitled"
        showCopyNotification = true
        
        // Hide the notification after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopyNotification = false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Simple Reminders")
                    .font(.headline)
                Spacer()
                Toggle("Show Completed", isOn: $showCompleted)
                    .toggleStyle(.switch)
                    .focusable(false)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            .onAppear {
                keyboardManager.onUpArrow = {
                    navigateMenu(direction: -1)
                }
                keyboardManager.onDownArrow = {
                    navigateMenu(direction: 1)
                }
            }
            
            if showCopyNotification {
                Text("Copied link for '\(lastCopiedTitle)'")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .transition(.opacity)
            }
            
            switch remindersManager.authorizationStatus {
            case .notDetermined:
                ProgressView("Requesting access...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .authorized, .fullAccess:
                HSplitView {
                    // Lists sidebar
                    ScrollViewReader { proxy in
                        List(remindersManager.availableLists) { list in
                            HStack {
                                Text(list.title)
                                    .foregroundColor(remindersManager.selectedListIdentifier == list.id ? .white : .primary)
                                Spacer()
                                if remindersManager.selectedListIdentifier == list.id {
                                    let activeCount = remindersManager.reminders.filter { !$0.isCompleted }.count
                                    Text("\(activeCount)")
                                        .foregroundColor(remindersManager.selectedListIdentifier == list.id ? .white.opacity(0.8) : .secondary)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.2))
                                        )
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        focusState.focusedListId == list.id ? Color.gray.opacity(0.3) :
                                            remindersManager.selectedListIdentifier == list.id ? Color.accentColor :
                                            Color.clear
                                    )
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                focusState.focusedListId = list.id
                                remindersManager.selectList(list.id)
                            }
                            .id(list.id)
                        }
                        .frame(minWidth: 120, maxWidth: 150)
                        .listStyle(.sidebar)
                        .onAppear {
                            focusState.focusedListId = remindersManager.selectedListIdentifier
                        }
                        .onChange(of: scenePhase) { phase in
                            if phase == .active {
                                focusState.focusedListId = remindersManager.selectedListIdentifier
                                NSApp.keyWindow?.makeFirstResponder(nil)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    focusState.focusedListId = remindersManager.selectedListIdentifier
                                }
                            }
                        }
                        .onMoveCommand { direction in
                            switch direction {
                            case .up:
                                navigateList(direction: -1)
                            case .down:
                                navigateList(direction: 1)
                            default:
                                break
                            }
                        }
                        .onExitCommand {
                            selectFocusedList()
                        }
                    }
                    
                    // Reminders list
                    List(filteredReminders, id: \.calendarItemIdentifier) { reminder in
                        HStack {
                            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                                .onTapGesture {
                                    remindersManager.toggleCompletion(for: reminder)
                                }
                            Text(reminder.title ?? "Untitled")
                                .strikethrough(reminder.isCompleted)
                            Spacer()
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                                .scaleEffect(clickedLinkId == reminder.calendarItemIdentifier ? 0.7 : 1.0)
                                .animation(.spring(response: 0.2, dampingFraction: 0.5), value: clickedLinkId)
                                .onTapGesture {
                                    clickedLinkId = reminder.calendarItemIdentifier
                                    remindersManager.copyRichTextLink(for: reminder)
                                    // Reset the animation after a short delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        clickedLinkId = nil
                                    }
                                }
                        }
                        .contentShape(Rectangle()) // Make the entire row clickable
                        .onTapGesture {
                            remindersManager.copyRichTextLink(for: reminder)
                        }
                        .listRowHoverStyle(isSelected: false)
                    }
                    .listStyle(.inset)
                }
            case .denied, .restricted, .writeOnly:
                Text("Please enable Reminders access in System Settings")
            @unknown default:
                Text("Unknown authorization status")
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .background(
            EmptyView()
                .frame(width: 0, height: 0)
                .focusable()
                .onMoveCommand { direction in
                    switch direction {
                    case .up:
                        navigateList(direction: -1)
                    case .down:
                        navigateList(direction: 1)
                    default:
                        break
                    }
                }
                .onExitCommand {
                    selectFocusedList()
                }
        )
    }
    
    func navigateList(direction: Int) {
        print("Navigating list with direction: \(direction)")
        guard let currentIndex = remindersManager.availableLists.firstIndex(where: { $0.id == (focusState.focusedListId ?? remindersManager.selectedListIdentifier) }) else {
            print("No current index found, selecting first item")
            if let firstId = remindersManager.availableLists.first?.id {
                focusState.focusedListId = firstId
                remindersManager.selectList(firstId)
            }
            return
        }
        
        let newIndex = (currentIndex + direction + remindersManager.availableLists.count) % remindersManager.availableLists.count
        print("Moving from index \(currentIndex) to \(newIndex)")
        let newId = remindersManager.availableLists[newIndex].id
        focusState.focusedListId = newId
        remindersManager.selectList(newId)
    }
    
    func selectFocusedList() {
        print("Selecting focused list: \(focusState.focusedListId ?? "none")")
        if let focusedId = focusState.focusedListId {
            remindersManager.selectList(focusedId)
        }
    }
    
    func focusSelectedList() {
        print("Focusing selected list: \(remindersManager.selectedListIdentifier ?? "none")")
        focusState.focusedListId = remindersManager.selectedListIdentifier
    }
    
    private func navigateMenu(direction: Int) {
        let menuItems = remindersManager.availableLists
        guard !menuItems.isEmpty else { return }
        
        selectedMenuIndex = (selectedMenuIndex + direction + menuItems.count) % menuItems.count
        if let list = menuItems[safe: selectedMenuIndex] {
            remindersManager.selectList(list.id)  // This will update the reminders
            focusState.focusedListId = list.id
        }
    }
}

struct ListRowHoverModifier: ViewModifier {
    @State private var isHovered = false
    @FocusState private var isFocused: Bool
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected ? Color.accentColor :
                            isHovered || isFocused ? Color.gray.opacity(0.1) : Color.clear
                    )
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

extension View {
    func listRowHoverStyle(isSelected: Bool) -> some View {
        modifier(ListRowHoverModifier(isSelected: isSelected))
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ContentView()
        .environmentObject(RemindersManager())
}
