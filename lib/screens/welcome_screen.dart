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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            children: [
              const Spacer(flex: 1),

              _buildLogoSection(),

              const Spacer(flex: 2),

              // Description text (right above buttons)
              _buildDescription(),

              const SizedBox(height: 40),

              // Action buttons
              _buildActionButtons(context),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Logo image
        Image.asset(
          'assets/images/blue-logo.png',
          width: 400,
          height: 400,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 24),

        // App name
        /*const Text(
          'Calmawear',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: Color(0xFF0066FF),
            letterSpacing: 0.5,
            fontFamily: 'League Spartan',
          ),
        ),*/
      ],
    );
  }

  Widget _buildDescription() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Calmawear brings gentle support to every moment for autistic children and their families. Real-time care, thoughtful alerts.',
        style: TextStyle(
          fontSize: 14,
          color: Colors.black54,
          height: 1.6,
          fontFamily: 'League Spartan',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Log In button (filled)
        SizedBox(
          width: 250,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Log In',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                fontFamily: 'League Spartan',
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Sign Up button (outlined with light fill)
        SizedBox(
          width: 250,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signup');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCAD6FF),
              foregroundColor: const Color(0xFF0066FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                fontFamily: 'League Spartan',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
