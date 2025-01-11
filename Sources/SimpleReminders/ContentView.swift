import SwiftUI
import EventKit

struct ContentView: View {
    @StateObject private var remindersManager = RemindersManager.shared
    @AppStorage("showCompleted") private var showCompleted = false
    @State private var showCopyNotification = false
    @State private var lastCopiedTitle = ""
    @State private var clickedLinkId: String? = nil
    
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
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
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
                    List(remindersManager.availableLists) { list in
                        Text(list.title)
                            .foregroundColor(remindersManager.selectedListIdentifier == list.id ? .white : .primary)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(remindersManager.selectedListIdentifier == list.id ? Color.accentColor : Color.clear)
                            )
                            .onTapGesture {
                                remindersManager.selectList(list.id)
                            }
                    }
                    .frame(minWidth: 120, maxWidth: 150)
                    .listStyle(.sidebar)
                    
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
    }
}

#Preview {
    ContentView()
        .environmentObject(RemindersManager())
}
