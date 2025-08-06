# DocLinker

A Flutter app for document linking and management with a modern, professional design.

## Features

### ✅ Completed
- **Global Theme System**: Custom theme with teal-blue gradient branding
- **Splash Screen**: Animated logo with loading spinner and auth state checking
- **Onboarding Screen**: Swipeable PageView with 3 feature cards and dot indicators
- **Login Screen**: Email/password login with Google Sign-in, validation, and error handling(done)
- **Firebase Sign Up Screen**: Complete registration with name, email, password validation(working on)
- **Profile Setup Screen**: Additional user information collection
- **AuthService**: Centralized Firebase authentication with comprehensive error handling
- **State Management**: Riverpod integration for auth state management (working on)
- **Firebase Integration**: Ready for authentication (configured for development)

### 🎨 Design System
- **Colors**: Dark teal (#0F7C90), Light teal (#3CC9C8), Off-white background (#F7FAF9)
- **Typography**: Google Fonts Poppins for clean, modern text
- **Components**: Rounded borders (16-24px), soft shadows, gradient decorations
- **Animations**: Smooth fade and scale transitions

### 📱 App Features
- **Splash Screen**: Centered handshake logo with gradient background, animated fade-in and scale effects, circular loading spinner, 2.5-second delay with auth state checking
- **Onboarding Screen**: Swipeable PageView with 3 feature cards, animated dot indicators, skip button, and smooth navigation
- **Login Screen**: Email/password validation, Google Sign-in, forgot password dialog, loading indicators, error handling with snackbars
- **Firebase Sign Up Screen**: Complete registration with name, email, password validation, Firebase Auth integration, specific error handling(partially done)
- **Profile Setup Screen**: Additional user information (phone, age, gender) with skip option (next task)
- **AuthService**: Centralized authentication with comprehensive error handling, user profile management, email verification(partially done)
- **Navigation**: Automatic routing based on authentication state(working on)

## Setup

### Dependencies
```yaml
flutter_riverpod: ^2.4.9
firebase_core: ^2.24.2
firebase_auth: ^4.15.3
google_sign_in: ^6.1.6
google_fonts: ^6.1.0
```

### Firebase Configuration
1. Create a Firebase project
2. Run `flutterfire configure` to generate proper configuration
3. Replace mock values in `lib/firebase_options.dart` with actual Firebase config

### Development
```bash
flutter pub get
flutter run
```

## Project Structure
```
lib/
├── app_theme.dart          # Global theme system
├── main.dart              # App entry point with Riverpod
├── firebase_options.dart  # Firebase configuration
├── providers/
│   └── auth_provider.dart # Auth state management with Riverpod
├── services/
│   └── auth_service.dart  # Firebase authentication service
└── screens/
    ├── splash_screen.dart # Splash screen with animations
    ├── onboarding_screen.dart # Onboarding with PageView
    ├── login_screen.dart  # Login screen with validation
    ├── signup_screen.dart # Firebase sign up screen
    └── profile_setup_screen.dart # Profile setup screen
```

## Next Steps
- [ ] Implement complete Firebase authentication
- [ ] Build home screen with document management
- [ ] Add document linking functionality
- [ ] Integrate Chatbot (RAG)
- [ ] Implement user profile and settings
