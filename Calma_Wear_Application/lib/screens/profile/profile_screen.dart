// screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import './parent_profile.dart';
import './child_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentBottomNavIndex = 4; // Profile is at index 4

  void _onBottomNavTapped(int index) {
    if (index == _currentBottomNavIndex) return;

    switch (index) {
      case 0: // Home
        context.go('/home');
        break;
      case 1: // Planner
        context.go('/planner');
        break;
      case 2: // Community
        context.go('/community');
        break;
      case 3: // Chat
        context.go('/chat');
        break;
      case 4: // Profile (current screen)
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
            // Titre de la page
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: Column(
                children: [
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Image de l'utilisateur
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: user?.profileImageUrl == null
                          ? const LinearGradient(
                              colors: [Color(0xFF0066FF), Color(0xFF0080FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      image: user?.profileImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(user!.profileImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: user?.profileImageUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Nom de l'utilisateur
                  Text(
                    user?.name ?? 'John Doe',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Liste des options
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Parent Profile
                    _buildProfileOption(
                      icon: Icons.person_outline,
                      title: 'Parent Profile',
                      subtitle: 'Manage parent information',
                      iconColor: const Color(0xFF0066FF),
                      onTap: () {
                        context.push('/profile/parent');
                      },
                    ),

                    // Child Profile
                    _buildProfileOption(
                      icon: Icons.child_care_outlined,
                      title: 'Child Profile',
                      subtitle: user?.childName ?? 'No child profile',
                      iconColor: const Color(0xFF0066FF),
                      onTap: () {
                        context.push('/profile/child');
                      },
                    ),

                    // My Stories
                    _buildProfileOption(
                      icon: Icons.article_outlined,
                      title: 'My Stories',
                      subtitle: 'View your posted stories',
                      iconColor: const Color(0xFF0066FF),
                      onTap: () {
                        context.push('/profile/my-stories');
                      },
                    ),

                    // My Events
                    _buildProfileOption(
                      icon: Icons.event_outlined,
                      title: 'My Events',
                      subtitle: 'View registered events',
                      iconColor: const Color(0xFF0066FF),
                      onTap: () {
                        context.push('/profile/my-events');
                      },
                    ),

                    // Privacy Policy
                    _buildProfileOption(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Read our privacy terms',
                      iconColor: const Color(0xFF0066FF),
                      onTap: () {
                        context.push('/profile/privacy-policy');
                      },
                    ),

                    // Help
                    _buildProfileOption(
                      icon: Icons.help_outline,
                      title: 'Help',
                      subtitle: 'FAQ & Contact support',
                      iconColor: const Color(0xFF0066FF),
                      onTap: () {
                        context.push('/profile/help');
                      },
                    ),

                    // Logout Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF0F0F0),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            ).signOut();
                            context.go('/welcome');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF0066FF).withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.logout,
                                    color: Color(0xFF0066FF),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF0066FF),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Sign out from your account',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(
                                            0xFF0066FF,
                                          ).withOpacity(0.7),
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
                    ),

                    const SizedBox(height: 32),
                  ],
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

  // Widget pour les options de profil
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Icon avec background coloré
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.1),
                ),
                child: Icon(icon, color: iconColor, size: 24),
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
                    const SizedBox(height: 4),
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
              const SizedBox(width: 12),
              // Chevron
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
