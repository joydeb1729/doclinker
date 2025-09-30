# 🏥 DocLinker - Medical Appointment Management System

A comprehensive Flutter-based healthcare management application that connects doctors and patients through an intelligent appointment booking system with real-time communication capabilities.

## 🌟 Overview

DocLinker is a modern medical appointment management platform built with Flutter and Firebase, featuring separate interfaces for doctors and patients, intelligent doctor matching, real-time appointment scheduling, and integrated payment management.

## ✨ Key Features

### 🔐 **Authentication & User Management**
- **Multi-role Authentication**: Separate login flows for doctors and patients
- **Google Sign-in Integration**: Quick authentication with Google accounts
- **Profile Management**: Comprehensive user profiles with medical specializations
- **Role-based Navigation**: Automatic routing based on user type (doctor/patient)

### 👨‍⚕️ **Doctor Interface**
- **Doctor Dashboard**: Overview with appointment statistics and quick actions
- **Appointment Management**: 
  - View appointments by status (Today, Upcoming, Pending, By Date)
  - Confirm, decline, start, and complete appointments
  - Payment status tracking and management
  - Real-time appointment updates
- **Schedule Management**: Configure availability and time slots
- **Patient Communication**: Integrated messaging system

### 👤 **Patient Interface**
- **Doctor Discovery**: Browse and search doctors by specialization
- **Intelligent Matching**: AI-powered doctor recommendations based on symptoms
- **Appointment Booking**: 
  - Real-time availability checking
  - Multiple appointment types (consultation, follow-up, emergency)
  - Flexible scheduling with calendar integration
- **Appointment Tracking**: View booking history and status updates

### 💳 **Payment & Billing**
- **Fee Management**: Transparent pricing display
- **Payment Status Tracking**: Real-time payment confirmation
- **Doctor Payment Tools**: Mark appointments as paid
- **Billing History**: Complete transaction records

### � **Real-time Features**
- **Live Availability**: Real-time doctor schedule updates
- **Appointment Sync**: Instant status changes across all devices
- **Push Notifications**: Appointment reminders and updates
- **Status Tracking**: Complete appointment lifecycle management

## 🛠 Technical Stack

### **Frontend**
- **Flutter 3.24+**: Cross-platform mobile development
- **Dart**: Primary programming language
- **Riverpod**: State management and dependency injection
- **Google Fonts**: Typography system

### **Backend & Database**
- **Firebase Authentication**: Multi-provider auth system
- **Cloud Firestore**: NoSQL real-time database
- **Firebase Storage**: File and image storage
- **Firebase Functions**: Serverless backend logic

### **Key Dependencies**
```yaml
flutter_riverpod: ^2.4.9    # State management
firebase_core: ^3.4.1       # Firebase integration
firebase_auth: ^5.3.1       # Authentication
cloud_firestore: ^5.4.4     # Database
google_sign_in: ^6.2.0      # Google authentication
google_fonts: ^6.1.0        # Typography
http: ^1.1.0                 # HTTP requests
```

## 🏗 Architecture

### **Project Structure**
```
lib/
├── app_theme.dart                      # Global design system
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration
├── controllers/                       # Business logic controllers
├── models/                           # Data models
│   ├── appointment.dart              # Appointment model
│   ├── doctor_profile.dart           # Doctor profile model
│   └── user_profile.dart             # User profile model
├── pages/                            # Page layouts
├── providers/                        # Riverpod providers
├── screens/                          # UI screens
│   ├── doctor/                       # Doctor-specific screens
│   │   ├── doctor_dashboard.dart     # Doctor main interface
│   │   └── doctor_profile_screen.dart
│   ├── splash_screen.dart            # App initialization
│   ├── login_screen.dart             # Authentication
│   ├── home_screen.dart              # Patient home
│   ├── doctor_list_screen.dart       # Doctor browsing
│   ├── doctor_schedule_booking_screen.dart # Appointment booking
│   └── doctor_appointments_screen.dart     # Doctor appointments
├── services/                         # Business logic services
│   ├── auth_service.dart             # Authentication management
│   ├── appointment_service.dart      # Appointment operations
│   ├── doctor_matching_service.dart  # AI doctor matching
│   ├── doctor_availability_service.dart # Schedule management
│   ├── booking_service.dart          # Booking operations
│   └── chat_service.dart             # Communication features
├── utils/                            # Utility functions
└── widgets/                          # Reusable UI components
```

## 🎨 Design System

### **Color Palette**
- **Primary**: Teal Blue (#0F7C90) - Professional medical theme
- **Secondary**: Light Teal (#3CC9C8) - Accent and highlights  
- **Background**: Off-white (#F7FAF9) - Clean, clinical feel
- **Success**: Green - Confirmations and positive actions
- **Warning**: Orange - Pending states and notifications
- **Error**: Red - Alerts and critical actions

### **Typography**
- **Font Family**: Google Fonts Poppins
- **Hierarchy**: Clear heading and body text distinction
- **Accessibility**: High contrast ratios and readable sizes

### **UI Components**
- **Rounded Corners**: 8-16px for modern, friendly appearance
- **Cards**: Elevated surfaces with subtle shadows
- **Buttons**: Consistent padding and hover states
- **Forms**: Clear validation and error messaging

## 🚀 Getting Started

### **Prerequisites**
- Flutter SDK 3.24.0 or higher
- Dart SDK 3.5.0 or higher
- Android Studio / VS Code
- Firebase account
- Android/iOS development setup

### **Installation**

1. **Clone the repository**
```bash
git clone https://github.com/joydeb1729/doclinker.git
cd doclinker
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Firebase Setup**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Configure Firebase for your project
flutterfire configure
```

4. **Run the application**
```bash
# Development mode
flutter run

# Release mode  
flutter run --release
```

### **Firebase Configuration**

1. **Create Firebase Project**: Visit [Firebase Console](https://console.firebase.google.com)
2. **Enable Authentication**: Email/Password and Google Sign-in
3. **Setup Firestore**: Create database with security rules
4. **Configure Storage**: For profile images and documents
5. **Add Platform Apps**: Android and iOS configurations

### **Database Structure**

```
Firestore Collections:
├── users/                    # User profiles
├── doctor_profiles/          # Doctor information and availability
├── appointments/             # Appointment records
├── chats/                    # Communication threads
└── notifications/            # Push notification records
```

## 📱 Features Overview

### **Implemented ✅**

#### **Core Authentication**
- [x] Multi-role login (Doctor/Patient)
- [x] Google Sign-in integration
- [x] Profile setup and validation
- [x] Role-based navigation

#### **Doctor Management**
- [x] Doctor dashboard with analytics
- [x] Appointment management system
- [x] Schedule configuration
- [x] Payment status management
- [x] Patient communication tools

#### **Patient Experience**  
- [x] Doctor browsing and search
- [x] Real-time appointment booking
- [x] Schedule availability checking
- [x] Appointment history tracking

#### **Appointment System**
- [x] Multiple appointment types
- [x] Real-time status updates
- [x] Calendar integration
- [x] Payment tracking
- [x] Automated workflows

### **In Development 🔄**
- [ ] Advanced chat system with file sharing
- [ ] Video consultation integration  
- [ ] AI-powered symptom analysis
- [ ] Prescription management
- [ ] Insurance integration

### **Planned Features 📋**
- [ ] Multi-language support
- [ ] Offline functionality
- [ ] Advanced analytics dashboard
- [ ] Telemedicine capabilities
- [ ] Integration with medical devices
- [ ] AI diagnostic assistance

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### **Development Setup**
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

- **Documentation**: [Wiki](https://github.com/joydeb1729/doclinker/wiki)
- **Issues**: [GitHub Issues](https://github.com/joydeb1729/doclinker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/joydeb1729/doclinker/discussions)

## 🏆 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure  
- Google Fonts for typography
- Material Design for UI guidelines
- Open source community for inspiration

---

**Built with ❤️ using Flutter and Firebase**
