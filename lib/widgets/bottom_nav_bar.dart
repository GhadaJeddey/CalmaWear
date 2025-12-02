// widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0066FF), // Fond bleu
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withOpacity(0.3), // Ombre bleue
            blurRadius: 15,
            spreadRadius: 3,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0066FF), // Fond bleu
          selectedItemColor: Colors.white, // Icônes sélectionnées en blanc
          unselectedItemColor: Colors.white.withOpacity(
            0.7,
          ), // Icônes non sélectionnées en blanc avec opacité
          selectedFontSize: 0, // Cache les labels
          unselectedFontSize: 0, // Cache les labels
          showSelectedLabels: false, // Désactive l'affichage des labels
          showUnselectedLabels: false, // Désactive l'affichage des labels
          elevation: 0, // Supprime l'élévation par défaut,
          iconSize: 30,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '', // Label vide
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: '', // Label vide
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: '', // Label vide
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined),
              activeIcon: Icon(Icons.chat),
              label: '', // Label vide
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: '', // Label vide
            ),
          ],
        ),
      ),
    );
  }
}
