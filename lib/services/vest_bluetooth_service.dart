// services/vest_bluetooth_service.dart
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/sensor_data.dart';

// Connection state enum
enum VestConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

class VestBluetoothService {
  static final VestBluetoothService _instance =
      VestBluetoothService._internal();
  factory VestBluetoothService() => _instance;
  VestBluetoothService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _sensorCharacteristic;
  VestConnectionState _connectionState = VestConnectionState.disconnected;

  final StreamController<SensorData> _sensorDataController =
      StreamController<SensorData>.broadcast();

  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();

  final StreamController<VestConnectionState> _connectionStateController =
      StreamController<VestConnectionState>.broadcast();

  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<String> get connectionStatusStream =>
      _connectionStatusController.stream;
  Stream<VestConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  bool get isConnected => _connectedDevice != null;
  String get deviceName => _connectedDevice?.platformName ?? 'Not Connected';
  VestConnectionState get connectionState => _connectionState;

  // UUID for CalmaWear Vest (You'll set these in your ESP32 code)
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String SENSOR_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  /// Start scanning for CalmaWear vest
  Future<void> startScanning() async {
    try {
      _updateConnectionState(VestConnectionState.scanning);
      _connectionStatusController.add('Scanning...');

      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        _updateConnectionState(VestConnectionState.error);
        _connectionStatusController.add('Bluetooth not supported');
        return;
      }

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          // Look for CalmaWear vest (you can customize the device name)
          if (result.device.platformName.contains('CalmaWear') ||
              result.device.platformName.contains('ESP32')) {
            print('Found CalmaWear Vest: ${result.device.platformName}');
            connectToDevice(result.device);
            FlutterBluePlus.stopScan();
            break;
          }
        }
      });

      // Auto-stop scan after timeout
      Future.delayed(const Duration(seconds: 10), () {
        FlutterBluePlus.stopScan();
        if (_connectedDevice == null) {
          _updateConnectionState(VestConnectionState.disconnected);
          _connectionStatusController.add('No vest found');
        }
      });
    } catch (e) {
      print('Scan error: $e');
      _updateConnectionState(VestConnectionState.error);
      _connectionStatusController.add('Scan error: $e');
    }
  }

  /// Update connection state and notify listeners
  void _updateConnectionState(VestConnectionState newState) {
    _connectionState = newState;
    _connectionStateController.add(newState);
  }

  /// Connect to the vest device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _updateConnectionState(VestConnectionState.connecting);
      _connectionStatusController.add('Connecting...');

      // Connect to device
      await device.connect(autoConnect: true);
      _connectedDevice = device;

      _updateConnectionState(VestConnectionState.connected);
      _connectionStatusController.add('Connected to ${device.platformName}');
      print('Connected to ${device.platformName}');

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Find sensor service and characteristic
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() ==
            SERVICE_UUID.toLowerCase()) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() ==
                SENSOR_CHAR_UUID.toLowerCase()) {
              _sensorCharacteristic = characteristic;

              // Subscribe to notifications
              await characteristic.setNotifyValue(true);

              // Listen to sensor data
              characteristic.lastValueStream.listen((value) {
                _processSensorData(value);
              });

              print('Subscribed to sensor data');
              _connectionStatusController.add('Receiving data');
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Connection error: $e');
      _connectionStatusController.add('Connection failed');
      _connectedDevice = null;
    }
  }

  /// Process incoming sensor data from vest
  void _processSensorData(List<int> data) {
    if (data.length < 10) return; // Minimum expected data size

    try {
      // Parse data packet (format depends on your ESP32 implementation)
      // Example format: [HR, BR, Temp_H, Temp_L, Noise, Motion, ...]

      final heartRate = data[0].toDouble();
      final breathingRate = data[1].toDouble();
      final tempHigh = data[2];
      final tempLow = data[3];
      final temperature = tempHigh + (tempLow / 100.0);
      final noiseLevel = data[4].toDouble();
      final motion = data[5].toDouble();

      // Calculate stress score based on sensor readings
      final stressScore = _calculateStressScore(
        heartRate,
        breathingRate,
        temperature,
        noiseLevel,
        motion,
      );

      // Create sensor data object
      final sensorData = SensorData(
        heartRate: heartRate,
        breathingRate: breathingRate,
        temperature: temperature,
        noiseLevel: noiseLevel,
        motion: motion,
        stressScore: stressScore,
        timestamp: DateTime.now(),
      );

      // Emit to stream
      _sensorDataController.add(sensorData);
    } catch (e) {
      print('Data parsing error: $e');
    }
  }

  /// Calculate stress score from sensor readings
  double _calculateStressScore(
    double hr,
    double br,
    double temp,
    double noise,
    double motion,
  ) {
    double score = 0;

    // Heart rate stress (60-100 normal, >100 stressed)
    if (hr > 100)
      score += 25;
    else if (hr > 90)
      score += 15;

    // Breathing rate stress (12-20 normal, >20 stressed)
    if (br > 30)
      score += 25;
    else if (br > 25)
      score += 15;

    // Temperature stress (>37.5°C elevated)
    if (temp > 37.5) score += 15;

    // Environmental stress
    if (noise > 80) score += 15;
    if (motion > 70) score += 20;

    return score.clamp(0, 100);
  }

  /// Disconnect from vest
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _sensorCharacteristic = null;
        _updateConnectionState(VestConnectionState.disconnected);
        _connectionStatusController.add('Disconnected');
      }
    } catch (e) {
      print('Disconnect error: $e');
      _updateConnectionState(VestConnectionState.error);
    }
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _sensorDataController.close();
    _connectionStatusController.close();
    _connectionStateController.close();
  }
}
