

# Gojira

Retail Analytics App

## Table of Contents
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Requirements](#requirements)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [License](#license)

## Features
- User authentication (login/register)
- Product management (add, edit, view, delete)
- Cart and transaction management
- Sales analytics dashboard
- Dark/Light mode toggle
- Responsive UI for mobile

## Tech Stack
- Flutter
- Firebase Auth & Firestore
- Provider/ValueNotifier (for state management)

## Requirements
- Flutter SDK (3.x recommended)
- Dart SDK
- Firebase project (for Auth & Firestore)
- Android Studio or VS Code

## Installation
1. Clone this repository:
	```bash
	git clone https://github.com/yourusername/gojira.git
	cd gojira
	```
2. Install dependencies:
	```bash
	flutter pub get
	```
3. Set up Firebase:
	- Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective folders.
	- Configure Firebase Auth and Firestore in the Firebase console.
4. Run the app:
	```bash
	flutter run
	```

## Project Structure

```
lib/
  main.dart                # App entry point
  theme_controller.dart    # Theme (dark/light) logic
  models/                  # Data models (user, product, transaction, etc)
  screens/                 # UI screens (auth, dashboard, product, etc)
  services/                # Service classes (API, auth)
  widgets/                 # Reusable widgets (product card, etc)
test/                      # Widget and unit tests
android/, ios/, web/, ...  # Platform-specific files
pubspec.yaml               # Dependencies and metadata
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
