import SwiftUI
import EventKit

struct SettingsView: View {
    @AppStorage("showCompleted") private var showCompleted = false
    @AppStorage("defaultListId") private var defaultListId: String = ""
    @StateObject private var remindersManager = RemindersManager.shared
    
    var body: some View {
        Form {
            Section {
                Text("SimpleReminders Settings")
                    .font(.headline)
                Text("Version 1.0")
                    .foregroundColor(.secondary)
            }
            
            Section {
                Toggle("Show Completed Tasks", isOn: $showCompleted)
            }
            
            Section {
                Picker("Default List", selection: $defaultListId) {
                    ForEach(remindersManager.availableLists) { list in
                        HStack {
                            Circle()
                                .fill(Color(nsColor: list.color))
                                .frame(width: 8, height: 8)
                            Text(list.title)
                        }.tag(list.id)
                    }
                }
                .onChange(of: defaultListId) { newValue in
                    // Don't allow empty selection
                    if newValue.isEmpty {
                        if let inboxList = remindersManager.availableLists.first(where: { $0.title == "Inbox" }) {
                            defaultListId = inboxList.id
                            remindersManager.setDefaultList(inboxList.id)
                        }
                    } else {
                        print("Default list changed to: \(newValue)")
                        remindersManager.setDefaultList(newValue)
                    }
                }
            }
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}
