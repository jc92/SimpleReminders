import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Text("SimpleReminders Settings")
                .font(.headline)
            Text("Version 1.0")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}
