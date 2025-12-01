// screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/home_screen.dart';
import '../chat/chat_screen.dart';
import '../planner/planner_screen.dart';
import '../community/community_screen.dart';
import '../../widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentBottomNavIndex = 4;

  void _onBottomNavTapped(int index) {
    if (index == _currentBottomNavIndex) return;

    switch (index) {
      case 0: // Accueil
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1: // Chat
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatScreen(fromScreen: 'profile'),
          ),
          (route) => false,
        );
        break;
      case 2: // Planner
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PlannerScreen()),
        );
        break;
      case 3: // Communauté
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CommunityScreen()),
        );
        break;
      case 4: // Profil (déjà sur ProfileScreen)
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête profil
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.purple[100],
                    child: Icon(Icons.person, size: 60, color: Colors.purple),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Utilisateur',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? 'email@exemple.com',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Informations
            const Text(
              'Informations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Card(
              child: ListTile(
                leading: Icon(Icons.child_care, color: Colors.purple),
                title: const Text('Enfant'),
                subtitle: Text(user?.childName ?? 'Non renseigné'),
              ),
            ),

            Card(
              child: ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.purple),
                title: const Text('Âge de l\'enfant'),
                subtitle: Text(user?.childAge ?? 'Non renseigné'),
              ),
            ),

            const Spacer(),

            // Bouton déconnexion
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).signOut();
                  Navigator.pushReplacementNamed(context, '/welcome');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}
