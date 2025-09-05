# Smart Trip Planner 🧳✈️

A modern Flutter application for planning and managing your trips.

## Features ✨

- **🔐 User Authentication**: Secure login and registration system
- **🏠 Modern UI**: Beautiful, responsive design based on Figma mockups
- **💾 Web-Compatible Database**: Uses localStorage for web platform
- **💬 Chat Assistant**: Interactive chat for trip planning help
- **📋 Trip Management**: Create and manage your travel itineraries
- **🎨 Custom Theme**: Consistent design system with modern colors

## Screenshots 📱

The app features a modern design with:
- Splash screen with smooth animations
- Login/Register forms with gradient backgrounds
- Home dashboard with quick actions
- Bottom navigation for easy access
- User profile management

## Tech Stack 🛠️

- **Framework**: Flutter 3.35.3
- **State Management**: Riverpod
- **Database**: localStorage (Web-compatible)
- **Authentication**: Custom implementation with SHA-256 password hashing
- **UI**: Material Design 3 with custom theming

## Getting Started 🚀

### Prerequisites
- Flutter SDK (3.35.3 or higher)
- Dart SDK
- Chrome browser (for web development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/smart_trip_planner.git
   cd smart_trip_planner
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run -d chrome
   ```

## Project Structure 📁

```
lib/
├── core/
│   ├── models/          # Data models
│   ├── providers/        # Riverpod providers
│   ├── repositories/     # Data repositories
│   └── theme/           # App theming
├── presentation/
│   ├── pages/           # App screens
│   │   ├── auth/        # Login/Register pages
│   │   └── widgets/     # Reusable widgets
│   └── providers/       # UI providers
└── main.dart           # App entry point
```

## Authentication Flow 🔐

1. **Registration**: Create account → Navigate to Login
2. **Login**: Enter credentials → Password verification → Homepage
3. **Security**: SHA-256 password hashing
4. **Storage**: Web-compatible localStorage implementation

## Development Notes 📝

- The app is optimized for web platform
- Uses localStorage for data persistence
- Implements proper error handling and validation
- Responsive design works on different screen sizes

## Contributing 🤝

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact 📧

- **Developer**: Akshit Shah
- **Email**: akshit.shah@example.com
- **GitHub**: [@AkshitShah96](https://github.com/AkshitShah96)

---

Made with ❤️ using Flutter
