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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec temps
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heure
                  Text(
                    '16:04',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 0, color: Color(0xFFF0F0F0), thickness: 1),

            // Section profil
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                children: [
                  // Avatar avec gradient bleu
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0066FF), Color(0xFF0080FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Nom et email
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'John Doe',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'john.doe@email.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 0, color: Color(0xFFF0F0F0), thickness: 1),

            // Liste des options
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Parent Profile
                  _buildProfileOption(
                    icon: Icons.person_outline,
                    title: 'Parent Profile',
                    subtitle: 'Manage parent information',
                    isFirst: true,
                    onTap: () {
                      // TODO: Naviguer vers Parent Profile
                    },
                  ),

                  // Child Profile
                  _buildProfileOption(
                    icon: Icons.child_care_outlined,
                    title: 'Child Profile',
                    subtitle: user?.childName ?? 'No child profile',
                    onTap: () {
                      // TODO: Naviguer vers Child Profile
                    },
                  ),

                  // Favorite
                  _buildProfileOption(
                    icon: Icons.favorite_border,
                    title: 'Favorite',
                    subtitle: 'Your saved items',
                    onTap: () {
                      // TODO: Naviguer vers Favorite
                    },
                  ),

                  // Privacy Policy
                  _buildProfileOption(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy terms',
                    onTap: () {
                      // TODO: Ouvrir Privacy Policy
                    },
                  ),

                  // Settings
                  _buildProfileOption(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'App preferences & notifications',
                    onTap: () {
                      // TODO: Naviguer vers Settings
                    },
                  ),

                  // Help
                  _buildProfileOption(
                    icon: Icons.help_outline,
                    title: 'Help',
                    subtitle: 'FAQ & Contact support',
                    onTap: () {
                      // TODO: Naviguer vers Help
                    },
                  ),

                  // Logout - en rouge
                  Material(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        ).signOut();
                        Navigator.pushReplacementNamed(context, '/welcome');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFF0F0F0), width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.withOpacity(0.1),
                              ),
                              child: Icon(
                                Icons.logout,
                                color: Colors.red[600],
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sign out from your account',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red.withOpacity(0.7),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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

  // Widget pour les options de profil
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isFirst = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            border: Border(
              top: isFirst
                  ? BorderSide.none
                  : const BorderSide(color: Color(0xFFF0F0F0), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Icon avec background gris clair
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                ),
                child: Icon(icon, color: Colors.grey[800], size: 22),
              ),
              const SizedBox(width: 16),
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
