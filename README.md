# Know Your Rights - AI Legal Assistant

A comprehensive mobile application built with Flutter that provides AI-powered legal assistance, document generation, contract review, and access to legal resources.

## 📱 Demo

**Demo Video:** [https://youtu.be/lNI8TIl0it8?feature=shared](https://youtu.be/nJwfUVrIj3s)

**GitHub Repository:** [https://github.com/Afsaumutoniwase/jaclean.git](https://github.com/WamalwaSydney/Know-Your-Rights.git)

## 🎯 Project Overview

Know Your Rights is an AI-powered legal assistant app that helps users understand their legal rights, generate legal documents, review contracts, and access legal resources. The app leverages advanced AI models (Groq LLaMA 3.1) to provide intelligent legal guidance while maintaining user privacy and security through Firebase backend services.

### Key Features

- **AI Legal Assistant**: Interactive chat interface powered by Groq API (LLaMA 3.1-8B-Instant)
- **Contract Review**: Upload and analyze PDF/Word documents with AI-powered risk assessment
- **Legal Document Generation**: AI-assisted templates for NDAs, leases, wills, employment contracts, loan agreements, and power of attorney
- **Legal Library**: Access to legal definitions, guides, and professional document templates
- **PDF Generation**: Convert AI-generated documents to professional PDFs with save, share, and print capabilities
- **Document Compression**: Intelligent compression for large documents to optimize AI analysis
- **User Authentication**: Email/password and Google Sign-In with email verification
- **User Preferences**: Customizable theme (light/dark/system), notifications, language, and auto-save settings
- **Secure Storage**: Firebase Firestore for cloud data storage with real-time synchronization

## 🏗️ Architecture

The application follows Flutter Clean Architecture principles with BLoC pattern for state management:

```
lib/
├── api_keys.dart                    # API key configuration
├── main.dart                        # App entry point
├── firebase_options.dart            # Firebase configuration
├── bloc/                            # BLoC state management
│   └── preferences/
│       └── preferences_bloc.dart    # User preferences BLoC
├── core/
│   ├── config/
│   │   ├── api_config.dart         # Groq API configuration
│   │   ├── api_keys.dart           # Centralized API keys
│   │   └── env_config.dart         # Environment configuration
│   ├── constants.dart              # App-wide constants
│   ├── models/                     # Data models
│   │   ├── chat_message.dart
│   │   ├── contract.dart
│   │   ├── document.dart
│   │   └── legal_resource.dart
│   └── services/                   # Business logic services
│       ├── auth_service.dart       # Firebase authentication
│       ├── chat_service.dart       # AI chat with Groq API
│       ├── contract_service.dart   # Contract analysis
│       ├── document_analysis_service.dart  # PDF/Word text extraction & compression
│       ├── document_service.dart   # Document CRUD operations
│       ├── google_signin_service.dart  # Google authentication
│       ├── legal_library_service.dart  # Legal templates & resources
│       ├── pdf_service.dart        # PDF generation & management
│       ├── preferences_service.dart # User preferences with SharedPreferences
│       └── storage_service.dart    # Local file storage
├── screens/                        # UI screens
│   ├── auth/                       # Authentication screens
│   │   ├── authenticate.dart
│   │   ├── email_verification_screen.dart
│   │   ├── password_reset_screen.dart
│   │   ├── register_screen.dart
│   │   └── sign_in_screen.dart
│   ├── legal/                      # Legal document screens
│   │   ├── saved_documents_screen.dart
│   │   ├── template_editor_screen.dart
│   │   └── template_viewer_screen.dart
│   ├── main/                       # Main app screens
│   │   ├── ai_assistant_screen.dart
│   │   ├── contract_review_screen.dart
│   │   ├── document_editor_screen.dart
│   │   ├── document_list_screen.dart
│   │   ├── home_screen.dart
│   │   ├── legal_library_screen.dart
│   │   └── settings_screen.dart
│   ├── splash_screen.dart
│   └── wrapper.dart
└── widgets/                        # Reusable widgets
    ├── auth_card.dart
    ├── chat_bubble.dart
    └── google_sign_in_button.dart
```

## 🛠️ Technologies Used

### Frontend
- **Flutter SDK**: 3.0.0+
- **Dart**: 3.0.0+

### State Management
- **flutter_bloc**: 8.1.6 - BLoC pattern implementation
- **equatable**: 2.0.5 - Value equality
- **hydrated_bloc**: 9.1.5 - State persistence
- **provider**: 6.1.1 - Dependency injection

### Backend & Cloud Services
- **Firebase Core**: 3.4.0
- **Firebase Auth**: 5.1.0 - Authentication
- **Cloud Firestore**: 5.0.2 - Database
- **Firebase Storage**: 12.1.0 - File storage
- **Google Sign-In**: 6.2.1 - OAuth authentication

### AI & API Integration
- **Groq API**: LLaMA 3.1-8B-Instant model
- **http**: 1.2.0 - HTTP client

### Document Processing
- **syncfusion_flutter_pdf**: 25.1.35 - PDF text extraction
- **docx_to_text**: 1.0.1 - Word document text extraction
- **pdf**: 3.10.7 - PDF generation
- **printing**: 5.12.0 - PDF printing
- **flutter_markdown**: 0.6.18 - Markdown rendering

### Local Storage & File Management
- **shared_preferences**: 2.2.2 - Local key-value storage
- **path_provider**: 2.1.1 - File system paths
- **file_picker**: 10.3.3 - File selection
- **open_file**: 3.2.1 - File opening
- **permission_handler**: 11.1.0 - Runtime permissions

### Utilities
- **share_plus**: 7.2.1 - File sharing
- **url_launcher**: 6.2.3 - URL handling
- **intl**: 0.19.0 - Internationalization
- **uuid**: 4.0.0 - Unique identifiers

### Testing
- **flutter_test**: SDK
- **bloc_test**: For BLoC testing
- **flutter_lints**: 3.0.1 - Code quality

## 📋 Prerequisites

Before running this project, ensure you have:

1. **Flutter SDK** (version 3.0.0 or higher)
   ```bash
   flutter --version
   ```

2. **Android Studio** or **Xcode** (for iOS development)

3. **Firebase Project** with the following services enabled:
    - Authentication (Email/Password and Google)
    - Cloud Firestore
    - Storage

4. **Groq API Key**
    - Sign up at [Groq Console](https://console.groq.com)
    - Generate an API key

5. **Git** for cloning the repository

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Afsaumutoniwase/jaclean.git
cd legal_ai
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API Keys

Update the API key in `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  static const String groqApiKey = 'YOUR_GROQ_API_KEY_HERE';
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqModel = 'llama-3.1-8b-instant';
  // ... other configurations
}
```

### 4. Configure Firebase

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Add Android and iOS apps to your Firebase project
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place files in their respective directories:
    - Android: `android/app/google-services.json`
    - iOS: `ios/Runner/GoogleService-Info.plist`

5. Run FlutterFire CLI to configure:
```bash
flutterfire configure
```

### 5. Enable Firebase Services

In Firebase Console:
- **Authentication**: Enable Email/Password and Google sign-in
- **Firestore Database**: Create database in production mode
- **Storage**: Enable Firebase Storage

### 6. Run the Application

```bash
# Check devices
flutter devices

# Run on connected device
flutter run

# Run on specific device
flutter run -d <device_id>

# Build release APK (Android)
flutter build apk --release

# Build iOS app
flutter build ios --release
```

## 🧪 Running Tests

### Unit Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/preferences_service_test.dart

# Run tests with coverage
flutter test --coverage

# View coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Widget Tests

```bash
# Run widget tests
flutter test test/widget_test.dart
```

### BLoC Tests

```bash
# Run BLoC tests
flutter test test/bloc/preferences_bloc_test.dart
```

## 📱 Platform-Specific Setup

### Android Setup

1. Update `android/app/build.gradle`:
```gradle
minSdkVersion 21
targetSdkVersion 33
```

2. Add permissions in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS Setup

1. Update `ios/Podfile`:
```ruby
platform :ios, '12.0'
```

2. Add permissions in `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to upload documents</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to scan documents</string>
```

3. Run pod install:
```bash
cd ios
pod install
cd ..
```

## 🔑 Environment Variables

Create a `.env` file in the root directory (optional, for additional configuration):

```env
# API Configuration
GROQ_API_KEY=your_groq_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here

# Firebase Configuration (if not using FlutterFire)
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_APP_ID=your_app_id

# Environment
ENVIRONMENT=development
```

## 📄 Firebase Firestore Data Structure

### Collections Structure

```
users/
  {userId}/
    - email: string
    - displayName: string
    - createdAt: timestamp
    
    chat_history/
      {messageId}/
        - userId: string
        - text: string
        - isUser: boolean
        - timestamp: timestamp
    
    contracts/
      {contractId}/
        - userId: string
        - fileName: string
        - fileUrl: string
        - analysisResult: string
        - uploadedAt: timestamp
    
    documents/
      {documentId}/
        - userId: string
        - title: string
        - content: string
        - createdAt: timestamp
        - updatedAt: timestamp
```

### Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /chat_history/{messageId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /contracts/{contractId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /documents/{documentId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## 🎨 Features in Detail

### 1. AI Legal Assistant
- Real-time chat with Groq AI (LLaMA 3.1-8B-Instant)
- Context-aware legal guidance
- Document generation assistance
- Copy messages and export to PDF
- Rate limiting: 30 requests/minute

### 2. Contract Review
- Support for PDF and Word documents
- AI-powered risk assessment
- Comprehensive analysis with:
    - Document type identification
    - Key findings extraction
    - Risk level assessment (Low/Medium/High/Critical)
    - Recommendations
- Document compression for large files
- Analysis history with cloud storage

### 3. Legal Document Generation
- Professional templates for:
    - Non-Disclosure Agreement (NDA)
    - Residential Lease Agreement
    - Last Will & Testament
    - Employment Contract
    - Loan Agreement
    - Power of Attorney
- AI-assisted template filling
- PDF export with professional formatting
- Save, share, and print capabilities

### 4. Legal Library
- Searchable resource database
- Filter by type (Templates, Definitions, Guides)
- External links to legal resources
- Dynamic template rendering

### 5. User Preferences
- Theme modes: Light, Dark, System
- Notification settings
- Language selection (English, Spanish, French, Swahili)
- Auto-save documents
- Persistent storage with SharedPreferences

## 🐛 Troubleshooting

### Common Issues

1. **Flutter Doctor Issues**
   ```bash
   flutter doctor -v
   ```
   Fix any reported issues before running the app.

2. **Pod Install Fails (iOS)**
   ```bash
   cd ios
   pod deintegrate
   pod install
   cd ..
   ```

3. **Gradle Build Fails (Android)**
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

4. **Firebase Not Initialized**
    - Ensure Firebase configuration files are in correct locations
    - Run `flutterfire configure` again

5. **API Key Issues**
    - Verify Groq API key is correct in `lib/core/config/api_config.dart`
    - Check API key has not exceeded rate limits

6. **PDF Generation Fails**
    - Ensure storage permissions are granted
    - Check available storage space
    - Verify PDF Service is initialized correctly

## 📊 Testing Coverage

Current test coverage includes:
- Widget tests for ChatBubble component
- BLoC tests for PreferencesBloc
- Service tests for PreferencesService
- Unit tests for core business logic

Target coverage: 70%+ (see test results in documentation)

## 🔐 Security Considerations

1. **API Keys**: Never commit API keys to version control
2. **Firebase Rules**: Implement proper security rules for Firestore
3. **Input Validation**: All user inputs are validated before processing
4. **Authentication**: Email verification required before full access
5. **Data Encryption**: Firebase provides encryption at rest and in transit
6. **Rate Limiting**: Groq API calls are rate-limited to prevent abuse

## 📈 Performance Optimization

- Document compression reduces API token usage by up to 70%
- Lazy loading for chat messages (limit 100)
- Image caching for better performance
- Efficient state management with BLoC
- Optimized PDF generation with Syncfusion

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Team

| Name | Role | Contribution |
|------|------|-------------|
| Developer 1 | Project Lead | Overall architecture, AI integration |
| Developer 2 | Backend Developer | Firebase setup, authentication |
| Developer 3 | Frontend Developer | UI/UX implementation |
| Developer 4 | QA Engineer | Testing, documentation |

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Groq for providing powerful AI API
- Firebase for backend services
- Syncfusion for PDF processing
- OpenRouteService for mapping functionality

## 📞 Support

For questions or issues:
- Create an issue on GitHub
- Email: support@knowyourrights.app
- Documentation: [Wiki](https://github.com/WamalwaSydney/Know-Your-Rights.git)

## 🗺️ Roadmap

- [ ] Multi-language support
- [ ] Offline mode
- [ ] Voice input for AI assistant
- [ ] Advanced contract templates
- [ ] Integration with legal databases
- [ ] Collaborative document editing
- [ ] Desktop application

---

**Built with ❤️ using Flutter**
