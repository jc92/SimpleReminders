import SwiftUI
import EventKit

struct ContentView: View {
    @StateObject private var remindersManager = RemindersManager.shared
    
    var body: some View {
        VStack {
            Text("Simple Reminders")
                .font(.largeTitle)
                .padding()
            
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
                    
                    // Reminders list
                    List(remindersManager.reminders, id: \.calendarItemIdentifier) { reminder in
                        Text(reminder.title ?? "Untitled")
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
