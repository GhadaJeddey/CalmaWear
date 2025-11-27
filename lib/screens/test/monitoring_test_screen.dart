import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../models/sensor_data.dart';
import '../../models/alert.dart';

class MonitoringTestScreen extends StatefulWidget {
  const MonitoringTestScreen({Key? key}) : super(key: key);

  @override
  _MonitoringTestScreenState createState() => _MonitoringTestScreenState();
}

class _MonitoringTestScreenState extends State<MonitoringTestScreen> {
  @override
  void initState() {
    super.initState();
    // Initialiser le monitoring au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final monitoringProvider = Provider.of<MonitoringProvider>(
        context,
        listen: false,
      );
      monitoringProvider.initializeMonitoring();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Monitoring - CalmaWear'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Consumer<MonitoringProvider>(
            builder: (context, monitoringProvider, child) {
              return IconButton(
                icon: Icon(
                  monitoringProvider.isMonitoring
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  monitoringProvider.toggleMonitoring();
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Carte de statut du monitoring
            _buildMonitoringStatusCard(),

            const SizedBox(height: 20),

            // Données des capteurs en temps réel
            Expanded(flex: 2, child: _buildSensorDataCard()),

            const SizedBox(height: 20),

            // Alertes actives
            Expanded(flex: 3, child: _buildAlertsCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringStatusCard() {
    return Consumer<MonitoringProvider>(
      builder: (context, monitoringProvider, child) {
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  monitoringProvider.isMonitoring
                      ? Icons.sensors
                      : Icons.sensors_off,
                  color: monitoringProvider.isMonitoring
                      ? Colors.green
                      : Colors.grey,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monitoringProvider.isMonitoring
                            ? 'MONITORING ACTIF'
                            : 'MONITORING ARRÊTÉ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: monitoringProvider.isMonitoring
                              ? Colors.green
                              : Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monitoringProvider.isMonitoring
                            ? 'Collecte des données en cours...'
                            : 'Cliquez sur play pour démarrer',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Chip(
                  backgroundColor: monitoringProvider.isMonitoring
                      ? Colors.green
                      : Colors.red,
                  label: Text(
                    monitoringProvider.isMonitoring ? 'ACTIF' : 'ARRÊTÉ',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSensorDataCard() {
    return Consumer<MonitoringProvider>(
      builder: (context, monitoringProvider, child) {
        final sensorData = monitoringProvider.currentSensorData;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 DONNÉES CAPTEURS TEMPS RÉEL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),

                if (sensorData == null) ...[
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timelapse, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'En attente des données...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Métriques principales
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildMetricCard(
                          '❤️ Rythme Cardiaque',
                          '${sensorData.heartRate.round()}',
                          'BPM',
                          _getHeartRateColor(sensorData.heartRate),
                        ),
                        _buildMetricCard(
                          '🌬️ Rythme Respiratoire', // 👈 NOUVEAU
                          '${sensorData.breathingRate.round()}',
                          'resp/min',
                          _getBreathingRateColor(sensorData.breathingRate),
                        ),
                        _buildMetricCard(
                          '🌡️ Température',
                          sensorData.temperature.toStringAsFixed(1),
                          '°C',
                          _getTemperatureColor(sensorData.temperature),
                        ),
                        _buildMetricCard(
                          '😰 Score Stress',
                          '${sensorData.stressScore.round()}',
                          '%',
                          _getStressColor(sensorData.stressScore),
                        ),
                        _buildMetricCard(
                          '🔊 Niveau Bruit',
                          '${sensorData.noiseLevel.round()}',
                          'dB',
                          _getNoiseColor(sensorData.noiseLevel),
                        ),
                        _buildMetricCard(
                          '🌀 Agitation',
                          '${sensorData.motion.round()}',
                          '%',
                          _getMotionColor(sensorData.motion),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dernière mise à jour
                  Text(
                    'Dernière mise à jour: ${_formatTime(sensorData.timestamp)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String unit,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsCard() {
    return Consumer<MonitoringProvider>(
      builder: (context, monitoringProvider, child) {
        final alerts = monitoringProvider.activeAlerts;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '🚨 ALERTES ACTIVES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (alerts.isNotEmpty)
                      CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 12,
                        child: Text(
                          alerts.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                if (alerts.isEmpty) ...[
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 50,
                            color: Colors.green,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Aucune alerte active',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Toutes les métriques sont normales',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ListView.builder(
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return _buildAlertItem(alert, monitoringProvider);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertItem(Alert alert, MonitoringProvider monitoringProvider) {
    Color alertColor = _getAlertColor(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alertColor),
      ),
      child: ListTile(
        leading: Icon(_getAlertIcon(alert.type), color: alertColor),
        title: Text(
          alert.message,
          style: TextStyle(fontWeight: FontWeight.w500, color: alertColor),
        ),
        subtitle: Text(
          _formatTime(alert.timestamp),
          style: TextStyle(color: alertColor.withOpacity(0.7)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                _getSeverityText(alert.severity),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              backgroundColor: alertColor,
            ),
            if (!alert.isResolved) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.check, size: 20),
                onPressed: () {
                  monitoringProvider.resolveAlert(alert.id);
                },
                color: Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Fonctions utilitaires pour les couleurs
  Color _getHeartRateColor(double heartRate) {
    if (heartRate > 100) return Colors.red;
    if (heartRate > 90) return Colors.orange;
    return Colors.green;
  }

  Color _getBreathingRateColor(double breathingRate) {
    if (breathingRate > 35) return Colors.red;
    if (breathingRate > 30) return Colors.orange;
    return Colors.green;
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature > 37.8) return Colors.red;
    if (temperature > 37.2) return Colors.orange;
    return Colors.green;
  }

  Color _getStressColor(double stressScore) {
    if (stressScore > 85) return Colors.red;
    if (stressScore > 70) return Colors.orange;
    if (stressScore > 50) return Colors.yellow;
    return Colors.green;
  }

  Color _getNoiseColor(double noiseLevel) {
    if (noiseLevel > 80) return Colors.red;
    if (noiseLevel > 65) return Colors.orange;
    return Colors.green;
  }

  Color _getMotionColor(double motion) {
    if (motion > 70) return Colors.red;
    if (motion > 50) return Colors.orange;
    return Colors.green;
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.blue;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.high:
        return Colors.red;
      case AlertSeverity.critical:
        return Colors.purple;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.heartRate:
        return Icons.favorite;
      case AlertType.breathing:
        return Icons.air;
      case AlertType.temperature:
        return Icons.thermostat;
      case AlertType.stress:
        return Icons.sentiment_very_dissatisfied;
      case AlertType.noise:
        return Icons.volume_up;
      case AlertType.motion:
        return Icons.directions_run;
    }
  }

  String _getSeverityText(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return 'FAIBLE';
      case AlertSeverity.medium:
        return 'MOYEN';
      case AlertSeverity.high:
        return 'ÉLEVÉ';
      case AlertSeverity.critical:
        return 'CRITIQUE';
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}
