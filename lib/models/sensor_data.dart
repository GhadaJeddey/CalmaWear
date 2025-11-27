import 'package:cloud_firestore/cloud_firestore.dart';

class SensorData {
  final DateTime timestamp;
  final double heartRate; // BPM
  final double breathingRate; // Respirations par minute
  final double temperature; // °C
  final double noiseLevel; // dB
  final double motion; // Niveau d'agitation (0-100%)
  double stressScore; // Score de stress (0-100%)

  SensorData({
    required this.timestamp,
    required this.heartRate,
    required this.breathingRate, // 👈 AJOUTÉ
    required this.temperature,
    required this.noiseLevel,
    required this.motion,
    required this.stressScore,
  });

  // Méthode pour calculer le score de stress (avec breathingRate)
  static double calculateStressScore(
    double hr,
    double br, // 👈 NOUVEAU PARAMÈTRE
    double temp,
    double noise,
    double motion,
  ) {
    double score = 0;

    // Rythme cardiaque (poids: 30%)
    if (hr > 100)
      score += 30;
    else if (hr > 90)
      score += 20;
    else if (hr > 80)
      score += 10;

    // 👇 Rythme respiratoire (poids: 20%) - NOUVEAU
    if (br > 35)
      score += 20;
    else if (br > 30)
      score += 15;
    else if (br > 25)
      score += 5;

    // Température (poids: 15%)
    if (temp > 37.5)
      score += 15;
    else if (temp > 37.2)
      score += 8;

    // Niveau de bruit (poids: 15%)
    if (noise > 80)
      score += 15;
    else if (noise > 65)
      score += 8;

    // Agitation (poids: 20%)
    if (motion > 70)
      score += 20;
    else if (motion > 50)
      score += 10;

    return score.clamp(0, 100);
  }

  // Factory method pour créer depuis Firebase (plus tard)
  factory SensorData.fromMap(Map<String, dynamic> data) {
    return SensorData(
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      heartRate: (data['heartRate'] as num).toDouble(),
      breathingRate: (data['breathingRate'] as num).toDouble(),
      temperature: (data['temperature'] as num).toDouble(),
      noiseLevel: (data['noiseLevel'] as num).toDouble(),
      motion: (data['motion'] as num).toDouble(),
      stressScore: (data['stressScore'] as num).toDouble(),
    );
  }

  // Pour sauvegarder dans Firebase
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'heartRate': heartRate,
      'breathingRate': breathingRate,
      'temperature': temperature,
      'noiseLevel': noiseLevel,
      'motion': motion,
      'stressScore': stressScore,
    };
  }
}
