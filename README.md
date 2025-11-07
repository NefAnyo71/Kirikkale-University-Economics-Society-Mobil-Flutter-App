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

## 📂 Project Structure and Dart Files Functions

### 🏠 Main Files

#### `main.dart` - Application Entry Point
- **Function**: Main entry point and startup operations of the application
- **Features**:
  - Firebase initialization and configuration
  - User authentication system
  - Splash screen and loading screens
  - Application update control
  - Push notification configuration
  - Background tasks with Workmanager
  - Main page grid menu system
  - Account blocking control

#### `firebase_service.dart` - Firebase Operations
- **Function**: Firebase Firestore database operations
- **Features**:
  - Adding/retrieving feedback
  - Tournament application management
  - Database CRUD operations
  - Error management

### 🎯 Feature Modules

#### `admin_panel_page.dart` - Admin Panel
- **Function**: Admin login and management tools
- **Features**:
  - Secure admin login (username: kkuekonomi71)
  - Event management
  - Community news management
  - Voting system management
  - Student database
  - Blacklist management
  - AI scoring system
  - Course notes management

#### `current_economy.dart` - Current Economic News
- **Function**: Fetching economic news from Anadolu Agency RSS feed
- **Features**:
  - RSS feed reading and parsing
  - News filtering system
  - Dark/light mode
  - News reporting system
  - Sharing feature
  - Legal warning system
  - Automatic news update

#### `live_market.dart` - Live Market Tracking
- **Function**: Real-time tracking of cryptocurrency and stock prices
- **Features**:
  - CoinGecko API integration
  - Turkish stock simulation
  - Favorites system
  - Price charts (Syncfusion Charts)
  - Comparison feature
  - Search and filtering
  - Candlestick charts

#### `ders_notlari1.dart` - Course Notes Sharing System
- **Function**: Course notes sharing between students
- **Features**:
  - Faculty/department/course filtering
  - PDF file sharing
  - Like/dislike system
  - Add to favorites
  - Download counter
  - Legal warning and terms of use
  - Anonymous user system

#### `etkinlik_takvimi2.dart` - Event Calendar
- **Function**: Listing community events
- **Features**:
  - Firebase Firestore integration
  - Date sorting
  - Visual supported event cards
  - Gradient background design
  - Responsive design

#### `yaklasan_etkinlikler.dart` - Upcoming Events
- **Function**: Showing future events and setting alarms
- **Features**:
  - Remaining time calculation
  - Alarm setting system (for Samsung and other brands)
  - Clock app integration with Intent system
  - Real-time updates

#### `social_media_page.dart` - Social Media
- **Function**: Redirecting to community social media accounts
- **Features**:
  - Instagram and Twitter integration
  - External links with URL launcher
  - Responsive card design

#### `feedback.dart` - Feedback System
- **Function**: Collecting user feedback
- **Features**:
  - Anonymous feedback
  - Firebase Firestore recording
  - Email address (optional)
  - Form validation

#### `poll.dart` - Survey System
- **Function**: Creating and managing community surveys
- **Features**:
  - Multiple choice questions
  - Open-ended questions
  - Firebase Firestore recording
  - Anonymous survey system

#### `sponsors_page.dart` - Sponsors
- **Function**: Sponsorship information and contact
- **Features**:
  - Email integration
  - Sponsorship application system
  - Contact form

#### `account_settings_page.dart` - Account Settings
- **Function**: User account management
- **Features**:
  - Password change
  - Account deletion/deactivation
  - Notification settings (quiet hours)
  - Logout
  - User profile information

### 🔧 Service Files

#### `notification_service.dart` - Notification Service
- **Function**: Push notification management and event reminders
- **Features**:
  - Flutter Local Notifications
  - Event-based automatic notifications
  - 7 days, 1 day, 1 hour advance reminders
  - Notification history management
  - Debug and test functions

#### `services/local_storage_service.dart` - Local Storage
- **Function**: Local data management with SharedPreferences
- **Features**:
  - User session information
  - Application settings
  - Cache management

### 🔐 Admin Modules

#### `admin_yaklasan_etkinlikler.dart` - Event Management (Admin)
- **Function**: Adding/editing upcoming events for administrators
- **Features**:
  - Event title, detail and date management
  - Adding image URL
  - Event deletion and update
  - Firebase Firestore integration
  - Date and time picker

#### `admin_survey_page.dart` - Survey Results Management
- **Function**: Viewing and analyzing survey results
- **Features**:
  - Application evaluation statistics
  - Custom bar chart system
  - Categorizing user feedback
  - Community, application and event feedback
  - Real-time data updates

#### `cleaner_admin_page.dart` - Cleaning Management
- **Function**: Database cleaning and maintenance operations

#### `Topluluk_Haberleri_Yönetici.dart` - News Management
- **Function**: Adding/editing community news

#### `BlackList.dart` - Blacklist Management
- **Function**: User blocking system

#### `puanlama_sayfasi.dart` - AI Scoring
- **Function**: Student performance evaluation system

### 📊 Data Models and Helper Files

#### `ders_notlari1_new.dart` - Advanced Course Notes System
- **Function**: Next generation course notes sharing system
- **Features**:
  - Comprehensive legal warning system
  - User approval mechanism
  - Favorites system
  - Like/dislike system
  - Download counter
  - Anonymous user support
  - Advanced search and filtering

#### `DersNotlariAdmin1.dart` - Course Notes Admin Panel
- **Function**: Course notes management for administrators
- **Features**:
  - Note adding/editing/deleting
  - Search and filtering
  - Visual supported note cards
  - Term and exam type management

#### `DersNotlarimPage.dart` - Personal Course Notes
- **Function**: Users managing their personal course notes
- **Features**:
  - Course adding/deleting
  - Midterm and final photos
  - Local storage system
  - Image management

#### `uye_kayit_bilgileri.dart` - Member Registration Information Management
- **Function**: Viewing and managing registered members' information
- **Features**:
  - User search and filtering system
  - Pagination support
  - User account status management (active/disabled)
  - Password visibility control
  - Data export (CSV format)
  - Detailed user profile viewing
  - Sorting and filtering options

#### `oylama.dart` - Voting System
- **Function**: Creating and managing community votes
- **Features**:
  - Multiple choice voting
  - One vote per user
  - Real-time result display
  - Vote deletion authority
  - Vote tracking with SharedPreferences

#### `Cerezler.dart` - Site Session Tracking
- **Function**: Analyzing website session data
- **Features**:
  - IP address tracking
  - Session duration analysis
  - User approval status
  - Exit tracking
  - Unique visitor count

#### `BasvuruSorgulama.dart` - Application Management System
- **Function**: Managing trip and event applications
- **Features**:
  - Application search and filtering
  - Payment status tracking
  - Application deletion (double confirmation system)
  - Real-time application count
  - Detailed application information

#### `adminFeedBack.dart` - Feedback Management
- **Function**: Managing user feedback
- **Features**:
  - Firebase integration
  - Feedback listing
  - Refresh feature
  - Gradient background design

#### `community_news2_page.dart` - Community News Display
- **Function**: Showing community news to users
- **Features**:
  - Date-sorted news listing
  - Visual supported news
  - Gradient background
  - Real-time news updates

#### `uyekayıt.dart` / `uye_kayit.dart` - Member Registration
- **Function**: New member registration operations

#### `member_profiles_account.dart` - Member Profiles
- **Function**: Member profile information management

#### `website_applications_page.dart` - Web Applications
- **Function**: Managing website applications

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

## 📱 Application Architecture

### Folder Structure
```
lib/
├── services/           # Service layer
│   ├── local_storage_service.dart
│   └── notification_service.dart
├── admin/             # Admin panel
├── pages/             # Main pages
├── widgets/           # Reusable components
└── main.dart          # Application entry point
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

## 🔐 Authentication Notes

> **Important**: We are currently experiencing issues with packages like Google Sign-In. Account creation is currently local only. We are working on resolving these authentication issues.

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
