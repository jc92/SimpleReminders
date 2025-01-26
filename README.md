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

## Installation

You can install SimpleReminders in two ways:

### Option 1: Download the DMG
1. Go to the [Releases](https://github.com/jc92/SimpleReminders/releases) page
2. Download the latest `SimpleReminders-1.0.dmg`
3. Open the DMG file
4. Drag SimpleReminders to your Applications folder
5. Launch SimpleReminders from your Applications folder

### Option 2: Build from Source
1. Clone this repository
2. Open Terminal and navigate to the project directory
3. Run `swift build -c release`
4. The binary will be in `.build/release/SimpleReminders`

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
