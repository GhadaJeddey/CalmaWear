// screens/dashboard/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/planner_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../chat/chat_screen.dart';
import '../chat/chat_history_screen.dart';
import '../planner/planner_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomNavIndex = 0;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializePlannerProvider();
  }

  Future<void> _initializePlannerProvider() async {
    // Get user ID from auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null && user.id != null) {
      // Initialize planner provider with user ID
      final plannerProvider = Provider.of<PlannerProvider>(
        context,
        listen: false,
      );
      await plannerProvider.initialize(user.id!);
    }

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentBottomNavIndex) return;

    setState(() {
      _currentBottomNavIndex = index;
    });

    switch (index) {
      case 0: // Accueil (déjà sur HomeScreen)
        break;
      case 1: // Chat
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const ChatScreen(fromScreen: 'home'),
          ),
          (route) => false,
        );
        break;
      case 2: // Planner
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PlannerScreen()),
          (route) => false,
        );
        break;
      case 3: // Communauté
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CommunityScreen()),
          (route) => false,
        );
        break;
      case 4: // Profil
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    // Show loading while initializing
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Clear planner data on logout
              final plannerProvider = Provider.of<PlannerProvider>(
                context,
                listen: false,
              );
              await plannerProvider.clearUserData();

              // Sign out from auth
              await Provider.of<AuthProvider>(context, listen: false).signOut();

              // Navigate to welcome
              Navigator.pushReplacementNamed(context, '/welcome');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              'Bienvenue, ${user?.name ?? 'Utilisateur'}! 🎉',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Authentification réussie!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (user?.childName != null) ...[
              const SizedBox(height: 10),
              Text(
                'Enfant: ${user!.childName}',
                style: const TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ],
            const SizedBox(height: 30),
            // Quick actions section
            _buildQuickActions(context),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Accès rapide',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildQuickActionButton(
              icon: Icons.calendar_today,
              label: 'Planner',
              onTap: () {
                setState(() => _currentBottomNavIndex = 2);
                _onBottomNavTapped(2);
              },
              color: Colors.orange,
            ),
            _buildQuickActionButton(
              icon: Icons.chat,
              label: 'Chat IA',
              onTap: () {
                setState(() => _currentBottomNavIndex = 1);
                _onBottomNavTapped(1);
              },
              color: Colors.green,
            ),
            _buildQuickActionButton(
              icon: Icons.people,
              label: 'Communauté',
              onTap: () {
                setState(() => _currentBottomNavIndex = 3);
                _onBottomNavTapped(3);
              },
              color: Colors.purple,
            ),
            _buildQuickActionButton(
              icon: Icons.person,
              label: 'Profil',
              onTap: () {
                setState(() => _currentBottomNavIndex = 4);
                _onBottomNavTapped(4);
              },
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
