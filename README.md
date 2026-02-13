# Smart Home Control App

A Flutter application for controlling smart home devices, built as the Flutter equivalent of the React-based Smart Home Control App Design.

## Features

- **Device Management**: Control lights, thermostats, locks, cameras, and more
- **Automation**: Create custom routines and schedules
- **Security**: Monitor and control security systems
- **Energy Monitoring**: Track energy usage and get saving tips
- **Notifications**: Real-time alerts for home events
- **User Authentication**: Secure login and registration
- **Responsive Design**: Beautiful UI optimized for mobile devices

## Screens

- **Splash Screen**: App introduction with navigation logic
- **Onboarding**: First-time user introduction
- **Authentication**: Login, registration, and password recovery
- **Dashboard**: Home status overview and quick device controls
- **Devices**: Complete device management with categories
- **Device Details**: Individual device control and settings
- **Add Device**: Setup new smart devices
- **Automation**: Create and manage smart routines
- **Notifications**: View and manage alerts
- **Energy**: Monitor energy consumption
- **Security**: Control security systems
- **Profile**: User settings and preferences

## Technical Stack

- **Flutter**: Cross-platform mobile development framework
- **Provider**: State management
- **Go Router**: Navigation and routing
- **Shared Preferences**: Local data persistence
- **Google Fonts**: Typography
- **Flutter Animate**: Smooth animations

## Project Structure

```
lib/
├── app/
│   ├── providers/          # State management
│   │   ├── auth_provider.dart
│   │   └── theme_provider.dart
│   ├── router/             # Navigation
│   │   └── app_router.dart
│   ├── screens/            # UI screens
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── devices_screen.dart
│   │   ├── device_detail_screen.dart
│   │   ├── add_device_screen.dart
│   │   ├── automation_screen.dart
│   │   ├── create_automation_screen.dart
│   │   ├── notifications_screen.dart
│   │   ├── energy_screen.dart
│   │   ├── security_screen.dart
│   │   └── profile_screen.dart
│   └── widgets/           # Reusable components
│       ├── bottom_nav.dart
│       ├── device_card.dart
│       └── root_layout.dart
├── main.dart               # App entry point
└── pubspec.yaml           # Dependencies
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd smart_home_control
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Development

- Run in debug mode: `flutter run`
- Build for release: `flutter build apk` or `flutter build ios`
- Run tests: `flutter test`
- Analyze code: `flutter analyze`

## Key Features Implementation

### State Management
- Uses Provider pattern for state management
- AuthProvider handles user authentication and session
- ThemeProvider manages app theme preferences

### Navigation
- Go Router for declarative routing
- Protected routes with authentication checks
- Smooth transitions between screens

### UI Components
- Custom DeviceCard widget with animations
- Responsive BottomNav for navigation
- Consistent design system with Material 3

### Data Persistence
- Shared preferences for user settings
- Local storage for authentication state
- Theme preferences persistence

## Design System

### Colors
- Primary: #1E7F5C (Green)
- Secondary: #4ECDC4 (Teal)
- Accent: #FFC857 (Yellow)
- Background: White/Grey variations

### Typography
- Google Fonts (Inter) for consistent typography
- Hierarchical text sizing
- Proper contrast ratios for accessibility

### Components
- Cards with subtle shadows
- Rounded corners for modern look
- Consistent spacing and padding
- Smooth animations and transitions

## Next Steps

This Flutter app provides the foundation for the smart home control system. The next phase would involve:

1. **Backend Integration**: Connect to real smart home APIs
2. **Real-time Updates**: Implement WebSocket connections
3. **Advanced Features**: Add voice control, geofencing
4. **Cloud Sync**: Synchronize settings across devices
5. **Analytics**: Track usage patterns and insights

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.
