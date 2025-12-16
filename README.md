CalmaWear

CalmaWear is a cross-platform wearable health monitoring application built with Flutter and Python. It integrates real-time physiological data collection, stress detection using machine learning, and a user-friendly dashboard for visualization and community support.

## Features

- **Real-time Sensor Data**: Collects heart rate, breathing rate, movement, noise, and temperature from wearable devices.
- **Stress Detection**: Uses an LSTM-based model (Python API) to predict stress levels from physiological signals.
- **Weekly & Daily Statistics**: Aggregates and visualizes daily and weekly maximums and averages for key health metrics.
- **Firebase Integration**: Stores user data, authentication, and statistics in Firebase (Firestore and Realtime Database).
- **Community & Chat**: Users can join community events, share stories, and chat with others.
- **Cross-Platform**: Supports Android, iOS, Web, Windows, MacOS, and Linux.

## Project Structure

```
calma_wear/
├── android/           # Android native project
├── assets/            # Fonts and images
├── build/             # Build outputs
├── docs/              # Documentation
├── ios/               # iOS native project
├── lib/               # Main Flutter/Dart code
│   ├── config/        # Environment and API keys
│   ├── models/        # Data models
│   ├── providers/     # State management
│   ├── router/        # App routing
│   ├── screens/       # UI screens (dashboard, auth, etc.)
│   ├── services/      # Firebase, Bluetooth, API services
│   ├── utils/         # Utilities and constants
│   └── widgets/       # Reusable UI components
├── macos/             # macOS native project
├── stress_api/        # Python FastAPI backend for stress detection
├── test/              # Dart/Flutter tests
├── web/               # Web assets
├── windows/           # Windows native project
├── pubspec.yaml       # Flutter dependencies
├── firebase.json      # Firebase config
├── README.md          # Project documentation
```

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Python 3.8+](https://www.python.org/downloads/)
- [Firebase Project](https://console.firebase.google.com/)
- (Optional) Android Studio / Xcode for mobile builds

### 1. Clone the Repository
```sh
git clone https://github.com/GhadaJeddey/CalmaWear.git
cd CalmaWear
```

### 2. Flutter Setup
- Install dependencies:
	```sh
	flutter pub get
	```
- Configure Firebase:
	- Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective folders.
	- Update `lib/config/env.dart` and `lib/firebase_options.dart` with your Firebase project info.
- Run the app:
	```sh
	flutter run
	```

### 3. Python Stress API Setup
- Navigate to the API folder:
	```sh
	cd stress_api
	pip install -r requirements.txt
	```
- Start the API server:
	```sh
	uvicorn app:app --reload
	```
- The API will be available at `http://127.0.0.1:8000`.

### 4. Web & Desktop
- For web:
	```sh
	flutter run -d chrome
	```
- For Windows/Mac/Linux:
	```sh
	flutter run -d windows  # or macos, linux
	```

## Firebase Setup
- Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
- Enable Authentication (Email/Password, Google, etc.).
- Enable Firestore and Realtime Database.
- Download and add your platform-specific config files.

## Data Flow
- **Sensor Data**: Collected via Bluetooth and sent to the app.
- **Data Storage**: Synced to Firebase (Firestore for daily/weekly stats, Realtime DB for live data).
- **Stress Detection**: App sends sensor data to the Python API, which returns a stress score.
- **Visualization**: Dashboard displays real-time and historical data with charts and summaries.

## Key Files
- `lib/main.dart` — App entry point
- `lib/screens/dashboard/home_screen.dart` — Main dashboard UI
- `lib/services/weekly_stats_service.dart` — Firestore weekly stats logic
- `lib/services/realtime_sensor_service.dart` — Real-time data logic
- `stress_api/app.py` — Python FastAPI backend

## Testing
- Flutter: `flutter test`
- Python API: `pytest` or run `test_api.py`

## Contributing
1. Fork the repo and create your branch: `git checkout -b feature/your-feature`
2. Commit your changes: `git commit -am 'Add new feature'`
3. Push to the branch: `git push origin feature/your-feature`
4. Open a Pull Request

## License
This project is licensed under the MIT License.

## Contact
For questions or support, open an issue or contact the maintainer via GitHub.
