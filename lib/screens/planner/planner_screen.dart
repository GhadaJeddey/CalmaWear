// screens/planner/planner_screen.dart
import 'package:flutter/material.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificateur'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Section d'ajout
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.orange, size: 30),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Planifier une activité',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ajoutez des routines et activités',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Ajouter une activité
                      },
                      icon: Icon(Icons.arrow_forward_ios, color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Activités du jour
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Aujourd\'hui',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            Expanded(
              child: ListView(
                children: [
                  _buildActivityItem('Routine matinale', '08:00', Colors.green),
                  _buildActivityItem('Thérapie', '10:00', Colors.blue),
                  _buildActivityItem('Repas', '12:30', Colors.orange),
                  _buildActivityItem(
                    'Activité sensorielle',
                    '15:00',
                    Colors.purple,
                  ),
                  _buildActivityItem('Routine du soir', '19:30', Colors.indigo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.access_time, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(time),
        trailing: Icon(Icons.more_vert, color: Colors.grey),
        onTap: () {
          // TODO: Détails de l'activité
        },
      ),
    );
  }
}
