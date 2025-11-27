import 'package:flutter/material.dart';
import '../utils/constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // En-tête avec logo
              _buildHeader(),

              const SizedBox(height: 40),

              // Titre principal
              _buildTitle(),

              const SizedBox(height: 16),

              // Description
              _buildDescription(),

              const Spacer(),

              // Boutons d'action
              _buildActionButtons(context),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Icon(
        Icons.health_and_safety,
        size: 50,
        color: Color(AppConstants.primaryColor),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Bienvenue sur CalmaWear',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription() {
    return const Text(
      'Votre compagnon pour accompagner votre enfant autiste au quotidien. Surveillance en temps réel, alertes intelligentes et soutien personnalisé.',
      style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Bouton Se connecter
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Se connecter'),
          ),
        ),

        const SizedBox(height: 16),

        // Bouton Créer un compte
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signup');
            },
            child: const Text('Créer un compte'),
          ),
        ),
      ],
    );
  }
}
