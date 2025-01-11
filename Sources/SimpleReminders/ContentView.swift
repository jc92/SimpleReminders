import SwiftUI
import EventKit

struct ContentView: View {
    @StateObject private var remindersManager = RemindersManager.shared
    @State private var showCompleted = false
    @State private var showCopyNotification = false
    @State private var lastCopiedTitle = ""
    @State private var clickedReminderId: String? = nil
    
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
        VStack {
            Text("Simple Reminders")
                .font(.largeTitle)
                .padding()
            
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
                            .onTapGesture {
                                remindersManager.selectList(list.id)
                            }
                    }
                    .frame(minWidth: 200)
                    
                    VStack {
                        // Filter toggle
                        Toggle("Show Completed", isOn: $showCompleted)
                            .padding(.horizontal)
                        
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
                                    .scaleEffect(clickedReminderId == reminder.calendarItemIdentifier ? 0.7 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: clickedReminderId)
                                    .onTapGesture {
                                        clickedReminderId = reminder.calendarItemIdentifier
                                        remindersManager.copyRichTextLink(for: reminder)
                                        // Reset the animation after a short delay
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            clickedReminderId = nil
                                        }
                                    }
                            }
                            .contentShape(Rectangle()) // Make the entire row clickable
                            .onTapGesture {
                                remindersManager.copyRichTextLink(for: reminder)
                            }
                        }
                    }
                }
            case .denied, .restricted, .writeOnly:
                Text("Please enable Reminders access in System Settings")
            @unknown default:
                Text("Unknown authorization status")
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

#Preview {
    ContentView()
        .environmentObject(RemindersManager())
}
