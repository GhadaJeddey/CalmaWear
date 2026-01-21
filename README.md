# CalmaWear

CalmaWear is a cross-platform wearable health monitoring system designed to collect real-time physiological data, detect stress using machine learning, and provide meaningful visualizations and community support through a user-friendly application. The system combines embedded hardware, a Flutter multi-platform application, and a Python machine-learning backend to deliver end-to-end health monitoring and stress analysis.

## Project Overview

CalmaWear enables continuous monitoring of physiological signals such as heart rate, breathing rate, motion, noise level, and temperature using a wearable device. The collected data is processed locally on the wearable, transmitted via Bluetooth, visualized in real time in the application, and analyzed using machine learning models to estimate stress levels.

## Tech Stack

### Frontend (Client Application)
- **Flutter (Dart)** — Cross-platform UI for Android, iOS, Web, Windows, macOS, and Linux  
  [https://docs.flutter.dev](https://docs.flutter.dev)
- **Bluetooth Classic** — Real-time communication with the wearable device  
  [https://www.bluetooth.com/specifications/specs/](https://www.bluetooth.com/specifications/specs/)

### Backend & Machine Learning
- **Python** — Backend and ML development  
  [https://www.python.org](https://www.python.org)
- **FastAPI** — High-performance REST API for stress prediction  
  [https://fastapi.tiangolo.com](https://fastapi.tiangolo.com)
- **LSTM (Long Short-Term Memory)** — Time-series stress prediction model  
  [https://ieeexplore.ieee.org/document/6795963](https://ieeexplore.ieee.org/document/6795963)
- **TensorFlow / Keras** — Neural network implementation  
  [https://www.tensorflow.org/guide/keras/rnn](https://www.tensorflow.org/guide/keras/rnn)

### Cloud & Database
- **Firebase Authentication** — User authentication
- **Cloud Firestore** — Persistent weekly and daily statistics
- **Firebase Realtime Database** — Live sensor data streaming  
  Firebase documentation: [https://firebase.google.com/docs](https://firebase.google.com/docs)

### Embedded System (Wearable Hardware)
- **ESP32-WROOM-32** — Main microcontroller  
  [https://www.espressif.com/en/products/socs/esp32](https://www.espressif.com/en/products/socs/esp32)

#### Sensors
- **MAX30102** — Heart rate and RR interval measurement  
  [https://www.analog.com/en/products/max30102.html](https://www.analog.com/en/products/max30102.html)
- **FSR402** — Breathing activity detection  
  [https://www.interlinkelectronics.com/fsr-402](https://www.interlinkelectronics.com/fsr-402)
- **MPU6050** — Motion and agitation detection  
  [https://invensense.tdk.com/products/motion-tracking/6-axis/mpu-6050](https://invensense.tdk.com/products/motion-tracking/6-axis/mpu-6050)
- **KY-038** — Ambient noise estimation  
  [https://www.handsontec.com/dataspecs/KY-038.pdf](https://www.handsontec.com/dataspecs/KY-038.pdf)

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

### Cross-Platform Support
- Android
- iOS
- Web
- Windows
- macOS
- Linux

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
