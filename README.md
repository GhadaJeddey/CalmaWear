# CalmaWear

CalmaWear is a cross-platform wearable health monitoring system designed to collect real-time physiological data, detect stress using machine learning, and provide meaningful visualizations and community support through a user-friendly application. The system combines embedded hardware, a Flutter multi-platform application, and a Python machine-learning backend to deliver end-to-end health monitoring and stress analysis.

## Project Overview

CalmaWear enables continuous monitoring of physiological signals such as heart rate, breathing rate, motion, noise level, and temperature using a wearable device. The collected data is processed locally on the wearable, transmitted via Bluetooth, visualized in real time in the application, and analyzed using machine learning models to estimate stress levels.

## Tech Stack

### Frontend (Client Application)
- **Flutter (Dart)** — Cross-platform UI for Android, iOS, Web, Windows, macOS, and Linux  
- **Bluetooth Classic** — Real-time communication with the wearable device  

### Backend & Machine Learning
- **Python** — Backend and ML development  
- **FastAPI** — High-performance REST API for stress prediction  
- **LSTM (Long Short-Term Memory)** — Time-series stress prediction model  
- **TensorFlow / Keras** — Neural network implementation
  
### Cloud & Database
- **Firebase Authentication** — User authentication
- **Cloud Firestore** — Persistent weekly and daily statistics
- **Firebase Realtime Database** — Live sensor data streaming  

### Embedded System (Wearable Hardware)
- **ESP32-WROOM-32** — Main microcontroller  

#### Sensors
- **MAX30102** — Heart rate and RR interval measurement  
- **FSR402** — Breathing activity detection  
- **MPU6050** — Motion and agitation detection  
- **KY-038** — Ambient noise estimation  

## Features

### Real-time Sensor Monitoring
- Heart rate (BPM)
- Heart rate variability (RMSSD)
- Breathing rate (RPM)
- Motion intensity
- Ambient noise level

### Stress Detection
- On-device rule-based stress scoring
- LSTM-based stress prediction via Python API

### Statistics & Insights
- Daily and weekly averages and maximums
- Historical health trend visualization

### Firebase Integration
- Secure authentication
- Real-time and persistent data storage

### Community & Chat
- Community events
- Story sharing
- In-app chat between users

## Embedded System Architecture

The wearable device is built around an ESP32-WROOM-32 microcontroller and performs the following tasks:

- Sensor initialization and calibration
- Real-time physiological data acquisition
- Noise filtering and feature extraction
- Stress state estimation
- Bluetooth Classic data transmission

### Stress States

The system classifies stress into:

- **CALM**
- **STRESSED**
- **CRISIS**

### Bluetooth Data Format

The wearable transmits processed data using a lightweight text-based format:
```
RPM=18.4
BPM=82.1
RMSSD=42.3
ACC=0.31
MIC=420
SCORE=3
STATE=STRESSED
```

This format allows efficient parsing and real-time visualization in the Flutter application.

## Solution Demo 
https://github.com/user-attachments/assets/349989b3-7a66-430c-bba1-69f242a926ea

## License

This project is licensed under the MIT License.  
[https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT)

## Contact

For questions, feedback, or support:

- Open an Issue in this repository
- Contact the maintainer via GitHub
