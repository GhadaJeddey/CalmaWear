class SensorData {
  final DateTime timestamp;
  final double breathingRate;
  final double heartRate;
  final double motion;
  final double temperature;
  final double noiseLevel;
  final double stressScore;

  SensorData({
    required this.breathingRate,
    required this.timestamp,
    required this.heartRate,
    required this.temperature,
    required this.noiseLevel,
    required this.motion,
    required this.stressScore,
  });

  // Méthode pour calculer le score de stress (simulé) | to update later
  static double calculateStressScore(
    double hr,
    double temp,
    double noise,
    double motion,
  ) {
    double score = 0;
    if (hr > 100) score += 40;
    if (temp > 37.5) score += 30;
    if (noise > 80) score += 20;
    if (motion > 70) score += 10;
    return score.clamp(0, 100);
  }
}
