import SwiftUI

struct SettingsView: View {
    @AppStorage("showCompleted") private var showCompleted = false
    
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
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}
