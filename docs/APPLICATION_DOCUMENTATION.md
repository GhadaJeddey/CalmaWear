# CalmaWear - Complete Application Documentation

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Application Overview](#application-overview)
3. [Technical Architecture](#technical-architecture)
4. [Core Functionalities](#core-functionalities)
5. [Technology Stack](#technology-stack)
6. [Security & Privacy](#security--privacy)
7. [Frontend Architecture](#frontend-architecture)
8. [Backend Architecture](#backend-architecture)
9. [AI Integration](#ai-integration)
10. [Hardware Integration](#hardware-integration)
11. [Data Management](#data-management)
12. [User Experience](#user-experience)
13. [Testing & Quality Assurance](#testing--quality-assurance)
14. [Deployment & DevOps](#deployment--devops)
15. [Future Enhancements](#future-enhancements)

---

## Executive Summary

**CalmaWear** is a comprehensive health monitoring application designed to track and manage stress levels in children with autism spectrum disorder (ASD). The application combines real-time biometric monitoring through a wearable vest with AI-powered assistance, community support, and personalized planning tools to provide holistic care for children and support for parents, teachers, and caregivers.

### Key Features
- Real-time stress monitoring with biometric sensors
- AI-powered chatbot for instant support and guidance
- Intelligent task planning and scheduling
- Community platform for shared experiences
- SMS alerts to teachers and caregivers
- Offline functionality with local data caching
- Bluetooth connectivity with physical vest hardware

---

## Application Overview

### Purpose
CalmaWear addresses the critical need for continuous stress monitoring in children with autism. By providing real-time alerts and actionable insights, it enables proactive intervention and support from parents, teachers, and healthcare providers.

### Target Users
1. **Parents/Guardians**: Primary users who monitor their child's well-being
2. **Teachers/Educators**: Receive SMS alerts during school hours
3. **Children with ASD**: Direct beneficiaries of stress monitoring
4. **Healthcare Providers**: Access to historical data and trends

### Problem Solved
- Early detection of stress episodes in non-verbal or minimally verbal children
- Automated alerts to support networks
- Data-driven insights for intervention strategies
- Community support for isolated families
- Personalized task planning to reduce daily stressors

---

## Technical Architecture

### Architecture Pattern
CalmaWear follows a **client-server architecture** with a **Provider state management pattern** for Flutter:

```
┌─────────────────────────────────────────────────────────────┐
│                      Frontend (Flutter)                      │
│  ┌────────────┐  ┌────────────┐  ┌──────────────────────┐  │
│  │   Screens  │  │  Widgets   │  │  Providers (State)   │  │
│  └─────┬──────┘  └─────┬──────┘  └──────────┬───────────┘  │
│        │               │                     │               │
│  ┌─────▼───────────────▼─────────────────────▼───────────┐  │
│  │              Services Layer (Business Logic)          │  │
│  └─────┬───────────────┬─────────────────────┬───────────┘  │
└────────┼───────────────┼─────────────────────┼──────────────┘
         │               │                     │
    ┌────▼────┐    ┌─────▼─────┐        ┌─────▼─────┐
    │Firebase │    │ Gemini AI │        │ Hardware  │
    │ Backend │    │    API    │        │ (Vest BLE)│
    └─────────┘    └───────────┘        └───────────┘
```

### Core Components

#### 1. Presentation Layer
- **Screens**: UI components organized by feature
- **Widgets**: Reusable UI components
- **Router**: GoRouter for declarative navigation

#### 2. State Management Layer
- **Providers**: ChangeNotifier-based state management
  - `AuthProvider`: User authentication state
  - `MonitoringProvider`: Real-time sensor data
  - `ChatProvider`: AI chat conversations
  - `PlannerProvider`: Task management
  - `CommunityProvider`: Stories and events

#### 3. Business Logic Layer
- **Services**: Encapsulate business logic and external integrations
  - `AuthService`: Firebase Authentication
  - `MonitoringService`: Sensor data processing
  - `ChatService`: Gemini AI integration
  - `PlannerService`: Task generation and management
  - `CommunityService`: Firestore CRUD operations
  - `SmsService`: Twilio SMS alerts
  - `VestBluetoothService`: BLE hardware communication
  - `RealtimeSensorService`: Firebase Realtime Database
  - `CloudinaryService`: Image upload and storage

#### 4. Data Layer
- **Models**: Data structures
  - `User`: Parent and child profiles
  - `SensorData`: Biometric readings
  - `ChatMessage`: Conversation data
  - `TodoItem`: Task information
  - `CommunityStory`: User stories
  - `CommunityEvent`: Community events
  - `Alert`: Stress notifications

---

## Core Functionalities

### 1. Authentication & User Management

#### Features
- Email/password authentication via Firebase Auth
- User profile creation with parent and child information
- Profile management (parent, child details, preferences)
- Child profile with:
  - Name, age, gender, date of birth
  - Profile photo (uploaded to Cloudinary)
  - Stress triggers (customizable list)
  - Teacher contact numbers for SMS alerts

#### Security Features
- Secure password storage (Firebase Auth)
- Email verification
- Session management
- Secure token-based authentication

#### User Flow
```
Welcome Screen → Sign Up / Login → Child Profile Setup → Dashboard
```

---

### 2. Real-Time Stress Monitoring

#### Data Sources
1. **Hardware Vest (Primary)**: Bluetooth Low Energy (BLE) connection
   - Heart rate sensor
   - Breathing rate sensor
   - Temperature sensor
   - Motion/accelerometer
   - Ambient noise sensor

2. **Demo Mode (Fallback)**: Synthetic data generation
   - Realistic patterns with occasional stress spikes
   - Used for testing and demos without hardware

#### Monitored Metrics
| Metric | Normal Range | Alert Threshold |
|--------|--------------|-----------------|
| Heart Rate | 60-100 BPM | >120 BPM |
| Breathing Rate | 15-40 breaths/min | >45 breaths/min |
| Temperature | 36.0-37.5°C | >38°C |
| Motion Level | 0-100% | >80% |
| Noise Level | 30-70 dB | >90 dB |
| **Stress Score** | 0-100% | **>70%** (User configurable) |

#### Stress Score Calculation
The stress score is a weighted composite of all metrics:

```dart
stressScore = (
  (normalizedHeartRate * 0.25) +
  (normalizedBreathingRate * 0.20) +
  (normalizedTemperature * 0.15) +
  (normalizedMotion * 0.20) +
  (normalizedNoise * 0.20)
) * 100
```

#### Alert System
When stress threshold is exceeded:
1. Visual alert in parent app (red banner)
2. SMS sent to all configured teacher phone numbers via Twilio
3. Alert logged to Firebase for history tracking
4. Crisis intervention popup with calming techniques

#### Data Visualization
- **Real-time cards**: Current readings with color-coded indicators
- **Line charts**: Historical trends (last 20 readings)
- **Weekly summary**: Average metrics displayed on home screen
  - Stable baseline values (±2-3 units)
  - Clear comparison with real-time data

---

### 3. AI-Powered Chatbot (Gemini Integration)

#### Purpose
Provides instant, context-aware support to parents with questions about:
- Child behavior and stress management
- Autism-specific guidance
- Coping strategies and techniques
- General parenting advice

#### Technical Implementation
- **Model**: Google Gemini 2.5 Flash
- **Context Awareness**: Includes child information in system prompt
  - Child name, age, gender
  - Known stress triggers
  - Recent stress levels
- **Response Style**: Concise (5-7 lines maximum)
- **Safety**: Content filtering enabled for harmful/inappropriate content

#### Features
- Multi-turn conversations with context retention
- Conversation history saved to Firestore
- Multiple conversation threads
- Demo mode with pre-generated responses (when API not configured)
- Welcome message personalized to user
- Markdown support for formatted responses

#### Example System Prompt
```
You are a helpful assistant for parents of children with autism.
The child's name is Alex, age 8, male.
Known triggers: loud noises, sudden changes, crowded spaces.
Current stress level: 45% (moderate).
Provide brief, actionable advice in 5-7 lines maximum.
```

---

### 4. Intelligent Task Planning

#### AI-Powered Task Generation
- **Model**: Google Gemini 2.5 Flash
- **Input**: Child context + date + existing tasks
- **Output**: 3-5 personalized daily tasks (5-8 words each)
- **Considerations**:
  - Child's age and capabilities
  - Known stress triggers (avoid triggering activities)
  - Daily routines and structure
  - Balance of activities (play, learning, rest)

#### Manual Task Management
- Add, edit, delete tasks
- Mark as complete/incomplete
- Recurring tasks (daily, weekly)
- Task categories with color coding
- Due dates and reminders

#### Default Tasks
- Pre-configured templates for common routines
- Customizable by parent
- Auto-schedule based on time of day

#### Week View
- 7-day calendar view
- Task distribution across week
- Quick navigation between dates
- Task completion tracking

#### Data Persistence
- Saved to Firestore per user
- Offline support with local caching
- Sync when connection restored

---

### 5. Community Platform

#### Stories Feature
- **User-Generated Content**: Parents share experiences and insights
- **Rich Text**: Support for formatted text, images
- **Engagement**: Likes, comments (planned)
- **Moderation**: Content guidelines and reporting
- **Categories**: Filter by topic (coping strategies, success stories, challenges)

#### Events Feature
- **Community Events**: Local support groups, workshops, webinars
- **Event Details**:
  - Title, description, date/time
  - Location (physical or virtual link)
  - Organizer information
  - RSVP functionality (planned)
- **Calendar View**: Upcoming events sorted by date
- **Notifications**: Reminders for registered events

#### Content Management
- Create, edit, delete own stories/events
- Image upload via Cloudinary
- Real-time updates via Firestore streams
- "My Stories" and "My Events" sections in profile

#### Privacy Controls
- Public posts visible to all users
- Optional anonymous posting (planned)
- Report inappropriate content

---

### 6. SMS Alert System (Twilio Integration)

#### Purpose
Automated SMS notifications to teachers/caregivers when child stress exceeds threshold during school hours.

#### Configuration
- Multiple teacher phone numbers (up to 5)
- Phone numbers stored securely in Firestore
- International format required (+country code)

#### Alert Message Format
```
🚨 CalmaWear Alert

Student: [Child Name]
Status: HIGH STRESS DETECTED

Stress Level: 85%
Heart Rate: 125 BPM
Time: 10:45

Please check on the student.
```

#### Twilio Integration
- REST API for SMS delivery
- Account SID and Auth Token stored in environment variables
- Configurable sender phone number
- Delivery confirmation tracking
- Error handling for failed deliveries

#### Cost Management
- SMS only sent when stress exceeds threshold
- Configurable cooldown period (e.g., max 1 SMS per 30 minutes)
- Demo mode available without actual SMS sending

---

### 7. Profile Management

#### Parent Profile
- Name, email, phone number
- Date of birth
- Profile photo (Cloudinary upload)
- Account settings
- Notification preferences

#### Child Profile
- Name, age, gender, date of birth
- Profile photo
- **Stress Triggers**: Customizable list
  - Pre-defined options (loud noises, crowds, changes)
  - Custom trigger input
  - Used for AI context and planning
- Medical information (optional, encrypted)
- Teacher contact management

#### Settings
- Stress threshold adjustment (50-90%)
- Notification toggles
- App theme/appearance (planned)
- Data export (planned)
- Account deletion

#### Privacy & Data Management
- "My Stories" - view and manage published stories
- "My Events" - view and manage created events
- Help & Support section
- Privacy Policy and Terms of Service

---

### 8. Offline Functionality

#### Local Data Caching (Hive)
- User profile data
- Recent sensor readings
- Task lists
- Chat conversation history
- Community posts (limited)

#### Sync Strategy
- Automatic sync when connection restored
- Conflict resolution for concurrent edits
- Background sync worker
- Visual indicators for sync status

#### Connectivity Monitoring
- Real-time connection status (Connectivity Plus)
- Automatic retry logic
- User notifications for offline mode
- Graceful degradation of features

---

## Technology Stack

### Frontend (Flutter 3.10.1+)

#### Core Framework
- **Flutter SDK**: Cross-platform mobile framework
- **Dart Language**: Type-safe, compiled language

#### State Management
- **Provider 6.1.1**: Simple, scalable state management
- **ChangeNotifier**: Reactive state updates

#### Routing & Navigation
- **GoRouter 17.0.0**: Declarative routing with deep linking
- **Nested navigation**: Bottom nav bar with independent stacks

#### UI Components
- **Material Design 3**: Modern, accessible design system
- **Custom Widgets**: Reusable component library
- **Animations 2.0.7**: Smooth transitions and micro-interactions

#### Charts & Visualization
- **Custom painting**: Hand-drawn line charts for sensor data
- **Color-coded indicators**: Stress level visualization

#### Fonts & Typography
- **League Spartan**: Primary font family (weights 100-800)
- **Noto Sans**: Fallback for international characters
- **NotoEmoji**: Emoji support

---

### Backend (Firebase Platform)

#### Firebase Authentication
- Email/password authentication
- User session management
- Token-based security
- Multi-device support

#### Cloud Firestore (NoSQL Database)
**Collections Structure**:

1. **users**: User profiles and settings
   ```json
   {
     "id": "user123",
     "email": "parent@example.com",
     "name": "John Doe",
     "phoneNumber": "+1234567890",
     "childName": "Alex",
     "childAge": "8",
     "childGender": "male",
     "childTriggers": ["loud_noises", "crowds"],
     "teacherPhoneNumbers": ["+1234567891", "+1234567892"],
     "stressThreshold": 70,
     "notificationsEnabled": true,
     "createdAt": "2025-01-15T10:30:00Z"
   }
   ```

2. **community_stories**: User stories
   ```json
   {
     "id": "story123",
     "authorId": "user123",
     "authorName": "Jane Smith",
     "title": "Our Journey with Sensory Tools",
     "content": "...",
     "imageUrl": "https://cloudinary.com/...",
     "likes": 45,
     "createdAt": "2025-01-20T14:00:00Z"
   }
   ```

3. **community_events**: Community events
   ```json
   {
     "id": "event123",
     "organizerId": "user456",
     "title": "Autism Support Group Meeting",
     "description": "...",
     "date": "2025-02-15T18:00:00Z",
     "location": "Community Center",
     "virtualLink": "https://zoom.us/...",
     "attendees": ["user123", "user456"]
   }
   ```

4. **chat_conversations**: AI chat history
   ```json
   {
     "id": "conv123",
     "userId": "user123",
     "title": "Managing Meltdowns",
     "messages": [
       {
         "id": "msg1",
         "content": "How can I handle meltdowns?",
         "isUser": true,
         "timestamp": "2025-01-20T10:00:00Z"
       }
     ],
     "createdAt": "2025-01-20T10:00:00Z"
   }
   ```

5. **planner_todos**: User tasks
   ```json
   {
     "id": "todo123",
     "userId": "user123",
     "title": "Sensory break at 2pm",
     "completed": false,
     "date": "2025-01-20",
     "category": "routine",
     "aiGenerated": true
   }
   ```

6. **alerts**: Stress alert history
   ```json
   {
     "id": "alert123",
     "userId": "user123",
     "childName": "Alex",
     "stressLevel": 85,
     "heartRate": 125,
     "timestamp": "2025-01-20T10:45:00Z",
     "notificationsSent": ["+1234567891"],
     "resolved": false
   }
   ```

#### Firebase Realtime Database
- Real-time sensor data streaming
- Low-latency updates
- WebSocket connections
- Automatic reconnection

**Structure**:
```json
{
  "sensor_data": {
    "user123": {
      "current": {
        "heartRate": 75,
        "breathingRate": 18,
        "temperature": 36.8,
        "motion": 35,
        "noiseLevel": 45,
        "stressScore": 42,
        "timestamp": 1705752000000
      },
      "history": [...]
    }
  }
}
```

#### Firebase Storage
- User profile photos (fallback)
- Community images (fallback)
- Chat media files
- Secure, scalable object storage

---

### Third-Party APIs & Services

#### 1. Google Gemini AI
- **Model**: gemini-2.5-flash
- **Purpose**: Chatbot and task generation
- **Configuration**:
  - Max output tokens: 1000-2000
  - Temperature: 0.7 (balanced creativity)
  - Safety settings: Low thresholds for harmful content
- **API Key Management**: Environment variables

#### 2. Twilio SMS
- **Purpose**: Teacher SMS alerts
- **Configuration**:
  - Account SID
  - Auth Token
  - Sender phone number
- **Cost**: Pay-per-message pricing
- **Delivery**: REST API with confirmation

#### 3. Cloudinary
- **Purpose**: Image hosting and optimization
- **Features**:
  - Automatic format conversion (WebP, AVIF)
  - Responsive image URLs
  - CDN delivery
  - Transformation API (resize, crop)
- **Configuration**:
  - Cloud name
  - API key
  - API secret

---

### Hardware Integration

#### CalmaWear Vest Specifications
- **Microcontroller**: ESP32 (Bluetooth + WiFi)
- **Sensors**:
  - Heart rate: MAX30102 (optical sensor)
  - Temperature: DS18B20 (digital sensor)
  - Motion: MPU6050 (accelerometer/gyroscope)
  - Ambient noise: MAX4466 (microphone)
  - Breathing rate: Piezo strain sensor (chest expansion)

#### Bluetooth Low Energy (BLE) Protocol
- **Service UUID**: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Characteristic UUID**: `beb5483e-36e1-4688-b7f5-ea07361b26a8`
- **Data Format**: JSON over BLE
  ```json
  {
    "hr": 75,
    "br": 18,
    "temp": 36.8,
    "motion": 35,
    "noise": 45,
    "timestamp": 1705752000
  }
  ```
- **Update Frequency**: Every 3 seconds
- **Power Management**: Sleep mode between readings

#### Flutter BLE Integration
- **Package**: flutter_blue_plus 1.32.12
- **Features**:
  - Device scanning
  - Connection management
  - Automatic reconnection
  - Battery status monitoring
- **Permissions**: Location (Android), Bluetooth (iOS/Android)

---

### Local Storage & Caching

#### Hive (NoSQL Local Database)
- **Purpose**: Offline data persistence
- **Features**:
  - Fast, lightweight
  - Encrypted storage option
  - Type-safe adapters
  - Auto-migration

**Boxes (Tables)**:
- `user_cache`: User profile
- `sensor_cache`: Recent sensor readings
- `chat_cache`: Conversation history
- `todo_cache`: Task lists
- `settings_cache`: App preferences

#### SharedPreferences
- Simple key-value storage
- User preferences (theme, notifications)
- Last sync timestamp
- Onboarding completion flags

---

## Security & Privacy

### Authentication Security

#### Firebase Authentication
- **Password Requirements**: Minimum 6 characters (enforced)
- **Secure Communication**: HTTPS/TLS encryption
- **Session Tokens**: Short-lived, auto-refresh
- **Multi-Device**: Automatic session management

#### Password Storage
- Passwords never stored in app (Firebase handles)
- Hashed and salted server-side (bcrypt)
- No password transmission to Firestore

---

### Data Privacy

#### Personal Information Protection
1. **Encryption at Rest**:
   - Firestore: Automatic AES-256 encryption
   - Local storage: Hive encryption enabled
   - Sensitive fields: Additional encryption layer

2. **Encryption in Transit**:
   - All API calls: HTTPS/TLS 1.3
   - Firebase: Encrypted WebSocket connections
   - BLE: Encrypted pairing

3. **Access Control**:
   - Firestore Security Rules:
     ```javascript
     match /users/{userId} {
       allow read, write: if request.auth.uid == userId;
     }
     match /community_stories/{storyId} {
       allow read: if true; // Public
       allow write: if request.auth.uid == resource.data.authorId;
     }
     ```

#### Data Minimization
- Only essential data collected
- Optional fields clearly marked
- No third-party analytics (planned: privacy-focused analytics)
- User can delete account and all data

#### Child Data Protection (COPPA Compliance)
- Parental consent required
- No direct child account creation
- Child data not sold or shared
- Minimal child information collected
- Clear privacy policy

---

### API Key Security

#### Environment Variables
- API keys stored in `lib/config/env.dart` (gitignored)
- Template file: `env.dart.template`
- CI/CD: Environment variables injection
- Never committed to version control

#### Key Rotation
- Regular rotation policy (every 90 days)
- Compromised key procedures documented
- Multi-environment keys (dev, staging, prod)

#### Git Security
- `.gitignore`: Excludes sensitive files
- Git hooks: Pre-commit checks for secrets
- History cleaned: `git filter-branch` used to remove accidentally committed secrets

---

### Network Security

#### HTTPS Only
- All external API calls use HTTPS
- Certificate pinning (planned)
- TLS 1.3 minimum

#### Input Validation
- All user inputs sanitized
- SQL/NoSQL injection prevention (Firestore safe by default)
- XSS prevention in community posts
- File upload validation (type, size, content)

---

### Privacy Policy & Compliance

#### User Rights
- **Right to Access**: Export personal data
- **Right to Deletion**: Delete account and all data
- **Right to Correction**: Update profile information
- **Right to Portability**: JSON export of data

#### Data Retention
- Active accounts: Data retained indefinitely
- Inactive accounts (2+ years): Data deleted
- Deleted accounts: 30-day recovery window, then permanent deletion

#### Third-Party Data Sharing
- **Firebase**: Processor agreement, GDPR-compliant
- **Gemini AI**: No data retention beyond session
- **Twilio**: SMS metadata only, no content storage
- **Cloudinary**: Image hosting only, no personal data

#### Geographic Compliance
- GDPR (Europe): Full compliance
- COPPA (USA): Child data protection
- HIPAA: Not healthcare provider, but best practices followed

---

## Frontend Architecture

### Screen Structure

#### Navigation Hierarchy
```
Splash Screen
  └─> Welcome Screen
       ├─> Sign Up → Child Profile → Home
       └─> Login → Home

Home (Bottom Nav Shell)
  ├─> Dashboard (Home Screen)
  ├─> Planner (Task Management)
  ├─> Community (Stories & Events)
  ├─> Chat (AI Assistant)
  └─> Profile
       ├─> Parent Profile
       ├─> Child Profile
       ├─> My Stories
       ├─> My Events
       ├─> Settings
       ├─> Help
       └─> Privacy Policy
```

#### Screen Responsibilities

**1. Splash Screen**
- Initial load (Firebase initialization)
- Check authentication state
- Redirect to Welcome or Home

**2. Welcome Screen**
- Onboarding introduction
- Sign Up / Login CTAs
- App branding and value proposition

**3. Sign Up / Login Screens**
- Form validation
- Firebase authentication
- Error handling
- Loading states

**4. Home Screen (Dashboard)**
- Real-time sensor data display
- Weekly metrics summary
- Quick actions (alerts, tasks)
- Navigation hub

**5. Planner Screen**
- Week view calendar
- Task list for selected day
- AI task generation dialog
- Task completion toggling

**6. Community Screen**
- Tabs: Stories, Events
- Feed display with infinite scroll
- Create story/event FAB
- Detail views

**7. Chat Screen**
- Message list (scrollable)
- Text input with send button
- Conversation history access
- Loading indicators

**8. Profile Screen**
- User information display
- Navigation to sub-profiles
- Settings and help links

---

### Widget Architecture

#### Reusable Components

**1. BottomNavBar** (`widgets/bottom_nav_bar.dart`)
- Stateless widget
- 5 navigation items with icons
- Active state highlighting
- Tap callbacks

**2. SensorCard** (`widgets/sensor_card.dart`)
- Displays single metric
- Color-coded based on value
- Animated value changes
- Icon and label

**3. StressIndicator** (`widgets/stress_indicator.dart`)
- Circular progress indicator
- Color gradient (green → red)
- Percentage label
- Pulsing animation on high stress

**4. LineChart** (`widgets/line_chart.dart`)
- Custom painting widget
- Displays time-series data
- Auto-scaling axes
- Touch interaction (planned)

**5. ChatBubble** (`widgets/chat_bubble.dart`)
- User vs AI message styling
- Markdown rendering
- Timestamp display
- Copy text functionality

**6. TodoCard** (`widgets/todo_card.dart`)
- Checkbox for completion
- Task title and description
- Swipe-to-delete gesture
- Edit button

**7. StoryCard** (`widgets/story_card.dart`)
- Image thumbnail
- Title, author, date
- Like count
- Tap to detail view

---

### State Management Patterns

#### Provider Pattern
All providers extend `ChangeNotifier` and follow this structure:

```dart
class ExampleProvider extends ChangeNotifier {
  // Private state
  ExampleData? _data;
  bool _isLoading = false;
  String? _error;

  // Public getters
  ExampleData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Public methods (mutate state, call notifyListeners)
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _service.fetchData();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

#### Provider Initialization
In `main.dart`, all providers are registered with `MultiProvider`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => MonitoringProvider()),
    ChangeNotifierProvider(create: (_) => ChatProvider()),
    ChangeNotifierProvider(create: (_) => PlannerProvider()),
    ChangeNotifierProvider(create: (_) => CommunityProvider()),
  ],
  child: MaterialApp.router(...)
)
```

#### State Access Patterns
```dart
// Read state
final authProvider = Provider.of<AuthProvider>(context);
final user = authProvider.currentUser;

// Listen to changes
final monitoringProvider = context.watch<MonitoringProvider>();

// Trigger actions
context.read<ChatProvider>().sendMessage('Hello');
```

---

### Routing & Deep Linking

#### GoRouter Configuration
```dart
GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
    GoRoute(path: '/welcome', builder: (_, __) => WelcomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => SignupScreen()),
    
    // Nested shell for bottom nav
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (_, __, child) => HomeShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => HomeScreen()),
        GoRoute(path: '/planner', builder: (_, __) => PlannerScreen()),
        GoRoute(path: '/community', builder: (_, __) => CommunityScreen()),
        GoRoute(path: '/chat', builder: (_, __) => ChatScreen()),
        GoRoute(path: '/profile', builder: (_, __) => ProfileScreen()),
      ],
    ),
  ],
)
```

#### Navigation Examples
```dart
// Push new route
context.go('/login');

// Pop current route
context.pop();

// Replace route
context.replace('/home');

// Pass parameters
context.go('/story/${storyId}');
```

---

## Backend Architecture

### Firebase Project Structure

#### Project ID: `calmawear-81263`

#### Enabled Services
1. Authentication (Email/Password)
2. Cloud Firestore (NoSQL database)
3. Firebase Realtime Database (Real-time sensor data)
4. Cloud Storage (File uploads)
5. Cloud Functions (Planned: scheduled tasks, triggers)
6. Cloud Messaging (Planned: push notifications)

---

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User documents - only owner can access
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Community stories - read public, write owner only
    match /community_stories/{storyId} {
      allow read: if true; // Public
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                               request.auth.uid == resource.data.authorId;
    }
    
    // Community events - same as stories
    match /community_events/{eventId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                               request.auth.uid == resource.data.organizerId;
    }
    
    // Chat conversations - only owner can access
    match /chat_conversations/{conversationId} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == resource.data.userId;
    }
    
    // Planner todos - only owner can access
    match /planner_todos/{userId}/todos/{todoId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Alerts - only owner and admin can access
    match /alerts/{alertId} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == resource.data.userId;
    }
  }
}
```

---

### Firebase Realtime Database Rules

```json
{
  "rules": {
    "sensor_data": {
      "$userId": {
        ".read": "auth != null && auth.uid == $userId",
        ".write": "auth != null && auth.uid == $userId"
      }
    }
  }
}
```

---

### Cloud Functions (Planned)

#### 1. Scheduled Data Cleanup
- Delete old sensor data (>30 days)
- Archive completed alerts (>90 days)
- Remove inactive user drafts

#### 2. Alert Aggregation
- Daily stress summary emails
- Weekly reports to parents
- Monthly insights dashboard

#### 3. Push Notifications
- In-app notifications for new community posts
- Alert notifications (backup to SMS)
- Task reminders

#### 4. Content Moderation
- Automated inappropriate content detection (community posts)
- Flag for manual review
- Auto-delete spam

---

## AI Integration

### Gemini AI Architecture

#### Model Selection: gemini-2.5-flash
**Rationale**:
- Fast response times (<2 seconds)
- Cost-effective for high volume
- Sufficient context window (32k tokens)
- Strong reasoning for domain-specific tasks

#### Context Management

**System Prompt Template**:
```
You are a compassionate assistant for parents of children with autism spectrum disorder (ASD).

Current Child Information:
- Name: {childName}
- Age: {childAge}
- Gender: {childGender}
- Known Stress Triggers: {triggersList}
- Current Stress Level: {currentStressScore}% ({stressStatus})

Your role is to:
1. Provide brief, actionable advice (5-7 lines maximum)
2. Be empathetic and supportive
3. Focus on practical strategies
4. Consider the child's specific triggers
5. Encourage professional help when appropriate

Never provide:
- Medical diagnoses
- Medication advice
- Legal counsel
- Emergency crisis intervention (direct to 911)

Keep responses concise and supportive.
```

#### Conversation Management
- Maximum 20 messages per conversation (context window)
- Oldest messages pruned when limit reached
- Important context retained (child info, triggers)
- New conversation button to reset context

#### Safety & Content Filtering
- Harm category thresholds: LOW
- Blocked content: harassment, hate speech, sexual content, dangerous content
- User input sanitization
- Output validation for harmful advice

---

### AI-Powered Task Generation

#### Prompt Engineering
```
Generate 3-5 daily tasks for a child with autism.

Child Context:
- Name: {childName}
- Age: {childAge}
- Gender: {childGender}
- Stress Triggers: {triggersList}
- Date: {selectedDate}
- Existing Tasks: {existingTasksList}

Requirements:
- Each task: 5-8 words maximum
- Age-appropriate activities
- Avoid known triggers
- Balance structure and flexibility
- Include sensory breaks
- Consider daily routine (morning, afternoon, evening)

Format: JSON array of strings
Example: ["Morning sensory break", "Practice counting to 20", "Outdoor play time"]
```

#### Task Categories
1. **Routines**: Daily structure (meals, hygiene)
2. **Learning**: Educational activities
3. **Play**: Recreational time
4. **Social**: Interaction opportunities
5. **Sensory**: Regulation activities
6. **Rest**: Downtime and relaxation

#### Validation
- Check for age-inappropriate content
- Verify task length (5-8 words)
- Ensure no trigger-related activities
- Validate JSON format

---

### Demo Mode (Offline AI)

When API keys are not configured:

#### Chatbot Demo Responses
- Pre-generated responses for common questions
- Context-free, generic advice
- Clearly labeled as "Demo Mode"
- Encourages API configuration for full functionality

#### Task Generation Demo
- Rule-based task generation
- Templates based on age ranges
- Random selection from pre-defined lists
- No personalization

---

## Hardware Integration

### ESP32 Vest Firmware

#### Sensor Reading Logic
```cpp
void loop() {
  // Read sensors every 3 seconds
  if (millis() - lastReadTime > 3000) {
    SensorData data;
    data.heartRate = readHeartRate();
    data.breathingRate = readBreathingRate();
    data.temperature = readTemperature();
    data.motion = readMotionLevel();
    data.noiseLevel = readNoiseLevel();
    data.timestamp = millis();
    
    // Send via BLE
    sendBLEData(data);
    lastReadTime = millis();
  }
}
```

#### BLE Service Setup
```cpp
BLEService vestService(SERVICE_UUID);
BLECharacteristic sensorCharacteristic(
  SENSOR_CHAR_UUID,
  BLECharacteristic::PROPERTY_READ | 
  BLECharacteristic::PROPERTY_NOTIFY
);

vestService.addCharacteristic(sensorCharacteristic);
BLE.addService(vestService);
```

#### Power Management
- Deep sleep between readings
- Wake on BLE connection
- Low-power mode when idle
- Battery level monitoring

---

### Flutter BLE Connection Flow

```dart
1. Scan for devices (FlutterBluePlus.startScan)
2. Filter by name ("CalmaWear" or "ESP32")
3. Connect to device (device.connect)
4. Discover services (device.discoverServices)
5. Find sensor characteristic (service.getCharacteristic)
6. Subscribe to notifications (characteristic.setNotifyValue)
7. Listen to data stream (characteristic.value.listen)
8. Parse JSON and update MonitoringProvider
```

#### Error Handling
- Connection timeout (10 seconds)
- Auto-reconnect on disconnect
- Fallback to demo mode
- User notifications for connection issues

---

## Data Management

### Data Flow Architecture

#### Real-Time Data Flow
```
Vest Sensors → BLE → Flutter App → Firebase Realtime DB
                                 ↓
                          MonitoringProvider
                                 ↓
                      UI Components (Real-time update)
```

#### Historical Data Flow
```
Firebase Realtime DB → RealtimeSensorService → Local Cache (Hive)
                                             ↓
                                  MonitoringProvider
                                             ↓
                              Charts and Weekly Summary
```

#### User Data Flow
```
User Input (Screens) → Providers → Services → Firebase Firestore
                                             ↓
                                    Local Cache (Hive)
```

---

### Caching Strategy

#### Sensor Data
- **Cache**: Last 100 readings per user
- **Refresh**: On new BLE data or Realtime DB update
- **Expiry**: 24 hours for historical data
- **Priority**: Real-time over cached

#### User Profile
- **Cache**: On login, update on change
- **Refresh**: On app startup if >1 hour old
- **Expiry**: Never (until logout)
- **Priority**: Cached first, then Firestore

#### Community Content
- **Cache**: Last 50 stories/events
- **Refresh**: On pull-to-refresh
- **Expiry**: 1 hour
- **Priority**: Firestore first, cached fallback

#### Chat History
- **Cache**: Current conversation + last 5
- **Refresh**: On conversation switch
- **Expiry**: 7 days
- **Priority**: Cached first for fast load

---

### Sync Logic

#### Online Mode
1. All operations directly to Firebase
2. Update local cache on success
3. UI reflects Firebase state

#### Offline Mode
1. Operations saved to local cache
2. Queued for sync when online
3. UI reflects local state (with indicator)

#### Sync Conflict Resolution
- Last-write-wins for simple data
- User prompt for critical conflicts (e.g., profile changes)
- Automatic merge for non-conflicting fields

---

## User Experience

### Onboarding Flow

#### First-Time User
1. **Splash Screen**: Brand introduction (2 seconds)
2. **Welcome Screen**: App overview, value proposition
3. **Sign Up**: Account creation with email/password
4. **Child Profile Setup**: Guided input of child information
   - Name, age, gender
   - Photo upload (optional)
   - Stress triggers selection
   - Teacher phone numbers
5. **Dashboard Tour**: Feature highlights (skippable)
6. **Hardware Setup** (optional): Vest pairing instructions

#### Returning User
1. **Splash Screen**: Auth state check
2. **Dashboard**: Direct navigation to home

---

### Accessibility

#### Visual
- High contrast mode (planned)
- Font size adjustment (system settings)
- Color-blind friendly palette
- Clear icons with text labels

#### Motor
- Large touch targets (min 44x44 dp)
- Swipe gestures with alternatives
- Voice input for chat (planned)
- Keyboard navigation (web)

#### Cognitive
- Simple, consistent navigation
- Clear visual hierarchy
- Minimal text, icons first
- Progress indicators for all actions

---

### Error Handling

#### User-Facing Errors
- **Friendly messages**: Avoid technical jargon
- **Actionable guidance**: What the user can do
- **Visual indicators**: Red text, icons, bottom sheets
- **Retry options**: Clear CTAs for recovery

#### Example Error Messages
- ❌ "Authentication failed with error code 500"
- ✅ "Couldn't sign in. Check your email and password, then try again."

---

### Loading States

#### Indicators
- **Spinner**: Short operations (<2 seconds)
- **Progress bar**: Long operations with known duration
- **Skeleton screens**: Content loading (community feed)
- **Shimmer effect**: Enhances skeleton screens

#### User Feedback
- Disable buttons during operations
- Show "Saving..." text
- Success animations (checkmark)
- Haptic feedback (vibration)

---

## Testing & Quality Assurance

### Testing Strategy (Planned)

#### Unit Tests
- Service layer logic
- Data model conversions
- Utility functions
- Calculation algorithms (stress score)

#### Widget Tests
- Individual widgets (SensorCard, ChatBubble)
- User interactions (button taps, text input)
- State changes (loading, error, success)

#### Integration Tests
- Complete user flows (sign up to dashboard)
- Firebase integration
- BLE connection flow
- Offline sync

#### End-to-End Tests
- Critical paths (authentication, stress alert)
- Cross-platform (Android, iOS, Web)
- Performance benchmarks

---

### Code Quality

#### Linting
- `flutter_lints 6.0.0`: Official linter rules
- Custom rules for project-specific patterns
- Pre-commit hooks: Enforce linting

#### Code Reviews
- Required for all pull requests
- Checklist: Security, performance, accessibility
- Automated checks: Build, tests, lint

#### Documentation
- Inline comments for complex logic
- README for each major service
- Architecture decision records (ADRs)

---

## Deployment & DevOps

### Build Configuration

#### Android
- **Min SDK**: 21 (Android 5.0 Lollipop)
- **Target SDK**: 34 (Android 14)
- **Signing**: Release keystore (secure storage)
- **Build Types**: Debug, Profile, Release
- **Flavors**: Dev, Staging, Production

#### iOS
- **Min Version**: iOS 12.0
- **Signing**: Automatic (Xcode)
- **Build Configurations**: Debug, Release
- **Provisioning Profiles**: Development, Distribution

#### Web
- **Renderer**: CanvasKit (better performance)
- **Build**: `flutter build web --release`
- **Hosting**: Firebase Hosting (planned)

---

### CI/CD Pipeline (Planned)

#### GitHub Actions Workflow
```yaml
name: Build and Test

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
  
  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

---

### Environment Management

#### Environments
1. **Development**: Local testing, demo data
2. **Staging**: Pre-production, real Firebase project
3. **Production**: Live app, real users

#### Configuration
- Environment-specific API keys
- Separate Firebase projects per environment
- Feature flags for gradual rollout

---

### Monitoring & Analytics (Planned)

#### Firebase Crashlytics
- Automatic crash reporting
- Stack traces and device info
- User impact analysis

#### Firebase Performance
- App startup time
- Screen rendering time
- Network request latency

#### Custom Analytics (Privacy-Focused)
- User flow tracking (no PII)
- Feature usage metrics
- Error rate monitoring

---

## Future Enhancements

### Short-Term (Next 3 Months)

#### 1. Push Notifications
- In-app notifications for community posts
- Task reminders
- Alert backup (if SMS fails)

#### 2. Advanced Charts
- Touch interactions (zoom, pan)
- Multi-metric comparison
- Export to PDF

#### 3. Social Features
- Comments on community posts
- Likes/reactions
- Follow other parents

#### 4. Voice Input
- Voice-to-text for chatbot
- Voice commands for navigation

---

### Medium-Term (3-6 Months)

#### 1. Machine Learning
- Predictive stress alerts (before threshold)
- Personalized task recommendations
- Trigger pattern recognition

#### 2. Wearable Integration
- Fitbit, Apple Watch support
- Google Fit / Apple HealthKit sync

#### 3. Multi-Child Support
- Multiple child profiles per parent
- Switch between children
- Family dashboard

#### 4. Telemedicine Integration
- Share reports with doctors
- Video consultation scheduling
- Medication tracking

---

### Long-Term (6-12 Months)

#### 1. AI-Powered Insights
- Weekly stress analysis reports
- Long-term trend predictions
- Personalized intervention strategies

#### 2. School Portal
- Teacher dashboard (web app)
- Real-time alerts in classroom
- Behavior tracking integration

#### 3. Gamification
- Achievement badges for children
- Progress visualization
- Reward system

#### 4. Internationalization
- Multi-language support
- Localized content
- Regional community events

---

## Conclusion

CalmaWear is a comprehensive, production-ready application that combines modern mobile development practices with cutting-edge AI and hardware integration. Its architecture prioritizes:

- **Security**: End-to-end encryption, GDPR compliance
- **Privacy**: Minimal data collection, user control
- **Scalability**: Cloud-native, modular design
- **Usability**: Accessible, intuitive interfaces
- **Reliability**: Offline support, error handling

The application serves a critical need in the autism care community, providing parents and educators with real-time insights and AI-powered support to ensure the well-being of children with ASD.

---

## Appendix

### Key Metrics

| Metric | Value |
|--------|-------|
| Total Lines of Code | ~15,000+ |
| Number of Screens | 20+ |
| Number of Services | 12 |
| Number of Models | 10 |
| Firebase Collections | 6 |
| Third-Party APIs | 3 |
| Supported Platforms | Android, iOS, Web |
| Minimum SDK (Android) | API 21 |
| Minimum iOS Version | 12.0 |

---

### Contact & Support

- **GitHub Repository**: [GhadaJeddey/CalmaWear](https://github.com/GhadaJeddey/CalmaWear)
- **Firebase Project**: calmawear-81263
- **Documentation**: `/docs` folder
- **API Setup Guide**: `/docs/API_SETUP.md`

---

**Document Version**: 1.0  
**Last Updated**: January 2025  
**Author**: CalmaWear Development Team
