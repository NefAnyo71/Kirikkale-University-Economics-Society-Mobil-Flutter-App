# 🎓 EKOS - Kırıkkale University Economics Community Mobile Application

<div align="center">
  <img src="assets/images/ekoslogo.png" alt="EKOS Logo" width="200"/>
  <br>
  <strong>Flutter mobile application I developed for Kırıkkale University Economics Community</strong>
</div>

## 📱 About the Project

KET (KKU Economics Community) is a modern mobile application developed with Flutter for Kırıkkale University Economics Community. The application offers comprehensive features such as community events, current economic news, course notes sharing, and social media integration.

## 🎥 Project Introduction Video

<div align="center">
  <a href="https://www.youtube.com/watch?v=3jnqW75B0Bk" target="_blank">
    <img src="https://img.youtube.com/vi/3jnqW75B0Bk/maxresdefault.jpg" alt="KET Project Introduction Video" width="600"/>
  </a>
  <br>
  <strong>📺 <a href="https://www.youtube.com/watch?v=3jnqW75B0Bk">KET Mobile Application and Website Introduction Video</a></strong>
  <br>
  <em>Detailed project introduction, features and usage guide</em>
</div>

---

**Version**: 6.8.9
**Developer**: Arif Özdemir 
**Platform**: Android (iOS support available)  
**Language**: Dart/Flutter  
**Database**: Firebase Firestore  
**Minimum SDK**: Android API 34 (Android 13)  
**Target SDK**: Android API 36 (Android 16)

## ✨ Features

### 📚 Education and Academic
- **Course Notes Sharing System**: Course notes sharing between members
- **My Course Notes**: Personal course notes management
- **Event Calendar**: Academic and social event tracking
- **Upcoming Events**: Notifications for future events

### 📰 News and Communication
- **Community News**: Current community announcements
- **Social Media Integration**: Access to community social media accounts
- **Feedback System**: Providing feedback about the application and community
- **Survey System**: Collecting member opinions

### 💰 Economy and Finance
- **Current Economy**: Latest economic developments
- **Live Market**: Real-time financial data
- **Economic Analysis**: Expert opinions and analysis

### 👥 Community Management
- **Member Registration System**: New member applications
- **Member Profiles**: Community member information
- **Admin Panel**: Special panel for community administrators
- **Sponsors**: Community sponsors and partnerships

### 🔔 Notification and Security
- **Push Notifications**: Instant notifications for important announcements
- **Account Security**: Secure login and account management
- **Offline Mode**: Some features without internet connection
- **Automatic Update**: Checking application updates

## 🛠️ Technologies

### Frontend
- **Flutter 3.6.1+** - Cross-platform mobile application development
- **Dart 3.6.1+** - Programming language
- **Material Design 3** - Modern UI/UX design

### Backend and Database
- **Firebase Core** - Backend infrastructure
- **Cloud Firestore** - NoSQL database
- **Firebase Authentication** - User authentication
- **Firebase Messaging** - Push notifications
- **Firebase Database** - Real-time database

### Important Packages
- **shared_preferences** - Local data storage
- **permission_handler** - System permissions management
- **url_launcher** - External links
- **image_picker** - Image selection and upload
- **syncfusion_flutter_charts** - Charts and graphs
- **workmanager** - Background tasks
- **in_app_update** - In-app update
- **flutter_local_notifications** - Local notifications
- **http** - HTTP requests
- **intl** - Internationalization and date formats
- **share_plus** - Content sharing

## 🚀 Installation

### Requirements
- Flutter SDK 3.6.1 or higher
- Dart SDK 3.6.1 or higher
- Android Studio / VS Code
- Java 17 (for Android development)
- Gradle 8.12
- Firebase account and project configuration
- Android SDK (API Level 21 or higher)

### Step by Step Installation

1. **Install Flutter**:
   ```bash
   # Check if Flutter is installed
   flutter doctor
   ```

2. **Clone the project**:
   ```bash
   git clone [repository-url]
   cd ket
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Firebase configuration**:
   - Add `android/app/google-services.json` file
   - Configure your project in Firebase Console

5. **Run the application**:
   ```bash
   flutter run
   ```

## 📋 Configuration

### Firebase Setup
1. Create a new project in Firebase Console
2. Add Android application (com.example.ekos)
3. Place `google-services.json` file in `android/app/` folder
4. Enable Firebase Authentication, Firestore, Cloud Messaging and Realtime Database
5. Configure security rules

### Required Permissions (Android)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Application Configuration
1. Check dependencies in `pubspec.yaml` file
2. Place Firebase configuration files
3. Configure Android signing certificates
4. Set up notification channels

## 🔧 Development Environment

### Debug Mode
```bash
flutter run --debug
```

### Release Mode
```bash
flutter build apk --release
```

### Profile Mode (Performance Analysis)
```bash
flutter run --profile
```

### Data Flow
1. **Firebase Firestore**: Main database
2. **SharedPreferences**: Local settings
3. **Firebase Auth**: User authentication
4. **Firebase Messaging**: Push notifications

## 🔐 Security Features

### User Authentication
- Firebase Authentication integration
- Anonymous login support
- Account blocking system
- Secure password management

### Data Security
- Firestore security rules
- User data encryption
- Secure storage of API keys
- Legal warning and terms of use

## 📊 Performance Optimization

### Database Optimization
- Firestore indexing
- Pagination
- Real-time listeners
- Cache management

### UI/UX Optimization
- Lazy loading
- Image optimization
- Responsive design
- Dark/light mode support

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

## 📈 Analytics and Monitoring

### Firebase Analytics
- User behavior analysis
- Screen view statistics
- Event tracking
- Crash reports

### Performance Monitoring
- Firebase Performance Monitoring
- Network request analysis
- Application startup times
- Memory usage

## 🚀 Deployment

### Google Play Store
1. Application signing
2. APK/AAB creation
3. Store listing
4. Version management

### Firebase App Distribution
1. Adding test users
2. Beta version distribution
3. Feedback collection

## 🔄 Update System

### Automatic Update
- In-app update API
- Mandatory update control
- User notification
- Update status tracking

## 📞 Support and Contact

### Developer Contact
- **Email**: arifkerem71@gmail.com
- **Community**: Kırıkkale University Economics Community

### Bug Report
1. Use GitHub Issues
2. Add detailed error description
3. Share screenshots
4. Specify device and version information

## 📄 License

This project is licensed under the MIT license. See the `LICENSE` file for details.

## 🙏 Contributors

- **Arif Özdemir** - Main Developer
- **Kırıkkale University Economics Community** - Project Sponsor

## 📝 Version History

### v6.8.9 (Current)
- Advanced course notes sharing system
- Admin panel improvements
- Notification system updates
- Performance optimizations
- AI KET added

### v5.x.x
- Basic features
- Firebase integration
- User interface improvements

## 🤖 KET Artificial Intelligence Assistant

<div align="center">
  <img src="assets/images/ketyapayzeka.png" alt="KET AI Assistant" width="120"/>
  <br>
  <strong>Smart community assistant powered by Google Gemini AI</strong>
</div>

### 🧠 Artificial Intelligence Features

#### **💬 Smart Chat System**
- **Google Gemini 1.5 Flash** model integration
- **Turkish language support** with natural conversation
- **KET knowledge base** with customized responses
- **Contextual understanding** and smart response generation
- **Firebase database integration** AI can access data in collections

#### **🎤 Multi-Communication Channels**
- **Voice message sending** and recording
- **Speech-to-Text** for voice questions
- **Text-to-Speech** for reading responses aloud
- **Visual analysis** with photo sending and description

#### **📚 Comprehensive Knowledge Base**
- **500+ community information** with detailed explanations
- **Event and organization** information
- **Course notes system** guidance
- **Membership and account management** support
- **Troubleshooting** and technical support

#### **🎨 Modern User Interface**
- **Dark/Light mode** support
- **Message copying** and deletion features
- **Timestamp** with message history
- **Frequently asked questions** quick access
- **Usage limits** with fair resource management

#### **⚡ Performance and Security**
- **Daily 10 messages** limit with resource optimization
- **10 messages in 5 minutes** spam protection
- **Chat history** local storage
- **API security** and error management

### 🚀 KET AI Usage Scenarios

#### **📋 Community Information**
```
"What is KET?"
"How can I become a member?"
"Are events free?"
"What are the contact details?"
```

#### **📖 Academic Support**
```
"How to share course notes?"
"How to get a certificate?"
"Are there internship opportunities?"
```

#### **🔧 Technical Support**
```
"Application not working"
"Can't receive notifications"
"I forgot my password"
```

#### **📊 Visual Analysis**
- Explaining economic charts
- Course note content analysis
- Evaluating event posters
- Interpreting financial tables

### 🎯 AI Assistant Advantages

- **24/7 Accessibility**: Always active support
- **Instant Response**: Fast and accurate information
- **Personalized**: Special greeting with username
- **Multilingual**: Turkish-focused natural language processing
- **Learnable**: Continuously developing knowledge base

## 🔮 Future Plans

### Near Term
- Expanding iOS support
- Offline mode improvements
- More language support
- Advanced analytics

### Long Term
- Web application development (Website will probably stay the same for a while)
- **Artificial intelligence integration** ✅ **COMPLETED**
- Expanding social features
- Microservice architecture

## 📱 Application Screenshots

<div align="center">
  <img src="https://r.resimlink.com/0BKyUzkbDhF.jpg" width="200"/>
  <img src="https://r.resimlink.com/mdVa90Y5_kc.jpg" width="200"/>
  <img src="https://r.resimlink.com/g0Dn6Hj7NR.jpg" width="200"/>
  <img src="https://r.resimlink.com/rZ5HXtwTLyi.jpg" width="200"/>
</div>

<div align="center">
  <img src="https://r.resimlink.com/6lVfg.jpg" width="200"/>
  <img src="https://r.resimlink.com/O_Fg0hs1.jpg" width="200"/>
  <img src="https://r.resimlink.com/tsz-JqXNA.jpg" width="200"/>
  <img src="https://r.resimlink.com/IFEgL.jpg" width="200"/>
</div>

<div align="center">
  <img src="https://r.resimlink.com/JL7fY61ykD3.jpg" width="200"/>
  <img src="https://r.resimlink.com/oxU_JkX7prD.jpg" width="200"/>
  <img src="https://r.resimlink.com/_zPQaNC.jpg" width="200"/>
  <img src="https://r.resimlink.com/E9PVRF.jpg" width="200"/>
</div>

<div align="center">
  <img src="https://r.resimlink.com/3md5lyQ6MFYL.jpg" width="200"/>
  <img src="https://r.resimlink.com/H72bxAdM.jpg" width="200"/>
  <img src="https://r.resimlink.com/_JiWaSqXU.jpg" width="200"/>
  <img src="https://r.resimlink.com/h7dALa4jn8mq.jpg" width="200"/>
</div>

<div align="center">
  <img src="https://r.resimlink.com/rik1c3NL-O.jpg" width="200"/>
  <img src="https://r.resimlink.com/EVcydXAKSlg.jpg" width="200"/>
  <img src="https://r.resimlink.com/X4j8V03mwNR.jpg" width="200"/>
  <img src="https://r.resimlink.com/GOwZu.jpg" width="200"/>
</div>

## 🎬 Media and Resources

### 📺 Video Content
- **[Project Introduction Video](https://www.youtube.com/watch?v=3jnqW75B0Bk)** - Comprehensive introduction of KET mobile application and website
- **Feature Demos** - Demonstration of the application's main features
- **Installation Guide** - Step-by-step installation and configuration

### 📚 Documentation
- **API Documentation** - Firebase and external API integrations
- **Developer Guide** - Code structure and development standards
- **User Manual** - Application usage guide

---

## 🎨 Design Notes

> **Note**: You may notice design differences in some pages of the application. This is because I haven't updated some pages from the old version of the application yet. I plan to completely redesign the entire application from scratch in the future.


---

**Note**: This README file is continuously updated. Follow the repository for the most current information.

<div align="center">
  <strong>Stay one step ahead in the world of economics with KET! 📈</strong>
  <br><br>
  <img src="https://img.shields.io/badge/Flutter-3.6.1+-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.6.1+-blue?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-Latest-orange?logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/Version-6.8.9-green" alt="Version">
  <br>
  <a href="https://www.youtube.com/watch?v=3jnqW75B0Bk">
    <img src="https://img.shields.io/badge/YouTube-Introduction_Video-red?logo=youtube" alt="YouTube Video">
  </a>
</div>
