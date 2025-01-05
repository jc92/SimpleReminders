# Simple Reminders

A native macOS application for managing reminders using SwiftUI and EventKit.

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Setup

1. Clone the repository:
```bash
git clone <your-repository-url>
cd SimpleReminders
```

2. Build and run the project:
```bash
swift run
```

## Project Structure

```
SimpleReminders/
├── Package.swift              # Swift package manifest
├── Sources/
│   └── SimpleReminders/
│       ├── main.swift         # Application entry point
│       ├── AppDelegate.swift  # Main application delegate
│       ├── ContentView.swift  # Main SwiftUI view
│       └── RemindersManager.swift  # Reminders management logic
```

## Features

- View and manage reminders from macOS Reminders app
- Split view interface with lists and reminders
- Native macOS window and menu integration
- Real-time updates when reminders change
- Support for reminder completion status

## Permissions

The app requires access to your Reminders. When you first launch the app, it will request permission to access your reminders. You can manage this permission in System Settings:

1. Open System Settings
2. Navigate to Privacy & Security → Reminders
3. Enable access for Simple Reminders

## Development

### Building from Source

1. Make sure you have Xcode Command Line Tools installed:
```bash
xcode-select --install
```

2. Open the project:
```bash
open Package.swift  # Opens in Xcode
```

Or build from command line:
```bash
swift build
```

### Running in Development

```bash
swift run
```

## Troubleshooting

1. If the app doesn't appear:
   - Make sure you've granted Reminders access
   - Check Console.app for any error messages
   - Try rebuilding with `swift build --clean`

2. If reminders don't load:
   - Verify Reminders access in System Settings
   - Restart the app
   - Make sure you have at least one Reminders list

## License

[Your chosen license]
