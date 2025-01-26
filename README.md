# SimpleReminders

A lightweight macOS menu bar app for quick access to your Apple Reminders. Built with SwiftUI and native Apple frameworks.

## Features

- 🔍 Quick access from menu bar
- ⚡️ Fast reminder creation
- 📝 Multiple reminder list support
- 🎯 Smart list filtering and search
- ⌨️ Global hotkey support
- 🔄 Real-time sync with Apple Reminders
- 🎨 Native macOS UI/UX
- 🔒 Privacy-focused (uses only local data)

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for development)

## Installation

### Option 1: Download the DMG
1. Go to the [Releases](https://github.com/jc92/SimpleReminders/releases) page
2. Download the latest `SimpleReminders-0.1.0-beta.dmg`
3. Open the DMG file
4. Drag SimpleReminders to your Applications folder
5. Launch SimpleReminders from your Applications folder

When you first launch the app, it will request permission to access your reminders. This is required for the app to function. You can manage this permission at any time in System Settings:

1. Open System Settings
2. Go to Privacy & Security → Reminders
3. Find SimpleReminders in the list and enable/disable access

### Option 2: Build from Source
1. Clone this repository
2. Open Terminal and navigate to the project directory
3. Run `swift build -c release`
4. The binary will be in `.build/release/SimpleReminders`

## Project Structure

```
SimpleReminders/
├── Sources/
│   └── SimpleReminders/
│       ├── Services/           # Core services for app functionality
│       │   ├── ReminderCacheService.swift    # Caching layer for reminders
│       │   ├── ReminderListService.swift     # Reminder list management
│       │   ├── TaskCreationService.swift     # Task creation handling
│       │   └── AppleScriptService.swift      # AppleScript integration
│       ├── Views/             # SwiftUI views
│       │   ├── TaskPicker/    # Main task creation interface
│       │   ├── ListPicker/    # List selection interface
│       │   ├── ReminderList/  # Reminder list display
│       │   └── TextInput/     # Custom text input components
│       ├── ViewModels/        # View models for data handling
│       ├── Managers/          # Business logic managers
│       └── Resources/         # App resources
```

## Architecture

- **MVVM Architecture**: Uses SwiftUI with MVVM pattern for clear separation of concerns
- **Service Layer**: Modular services for core functionality
- **Cache Layer**: Efficient caching system for better performance
- **Event-Driven**: Reactive updates using Combine framework
- **Native Integration**: Direct integration with Apple's EventKit

## Dependencies

- [HotKey](https://github.com/soffes/HotKey) - Global keyboard shortcut handling

## Development

```bash
# Build the project
swift build

# Run the app in development
swift run

# Build release version
swift build -c release
```

## Privacy

SimpleReminders only accesses your local Reminders data through Apple's EventKit framework. No data is sent to external servers.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details
