// screens/community/community_screen.dart
import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communauté'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête communauté
          Card(
            color: Colors.teal[50],
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.group, size: 60, color: Colors.teal),
                  const SizedBox(height: 16),
                  const Text(
                    'Rejoignez notre communauté',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Partagez vos expériences et obtenez du soutien',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Forums
          const Text(
            'Forums populaires',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          _buildForumCard(
            'Gestion des crises',
            'Discutez des stratégies',
            Icons.emergency,
            Colors.red,
          ),

          _buildForumCard(
            'Routines et transitions',
            'Partagez vos routines',
            Icons.schedule,
            Colors.blue,
          ),

          _buildForumCard(
            'Conseils sensoriels',
            'Astuces et outils',
            Icons.psychology,
            Colors.purple,
          ),

          _buildForumCard(
            'Soutien émotionnel',
            'Entraide entre parents',
            Icons.favorite,
            Colors.pink,
          ),

          // Bouton nouveau post
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: FloatingActionButton.extended(
              onPressed: () {
                // TODO: Créer un nouveau post
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle discussion'),
              backgroundColor: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForumCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: () {
          // TODO: Ouvrir le forum
        },
      ),
    );
  }
}
