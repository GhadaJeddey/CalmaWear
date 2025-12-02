import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _titleScaleAnimation;
  late Animation<Offset> _titleSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Animation de fondu global
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Animation d'agrandissement du logo (plus prononcée)
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Animation d'agrandissement du titre
    _titleScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Animation de glissement du titre (de plus bas vers sa position)
    _titleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
          ),
        );
  }

  void _startAnimationSequence() {
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0066FF),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // Logo agrandi avec animation
              _buildAnimatedLogo(),

              // Titre qui glisse juste en dessous
              _buildAnimatedTitle(),

              const SizedBox(height: 16),

              // Tagline
              _buildAnimatedSubtitle(),

              const Spacer(flex: 2),

              // Progress indicator
              _buildProgressIndicator(),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return ScaleTransition(
      scale: _logoScaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: 400, // Logo plus grand
          height: 400,
          child: Image.asset(
            'assets/images/white-logo-no-title.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return SlideTransition(
      position: _titleSlideAnimation,
      child: ScaleTransition(
        scale: _titleScaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const Column(
            children: [
              Text(
                'CalmaWear',
                style: TextStyle(
                  fontSize: 52, // Taille augmentée
                  fontWeight: FontWeight.w100, // Plus léger
                  color: Colors.white,
                  letterSpacing: 2.0, // Plus d'espacement
                  fontFamily: 'League Spartan',
                  height: 0.9, // Hauteur de ligne réduite
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSubtitle() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: const Text(
          'For Every Mind That Feels Deeply,\nThere\'s Calm Heart You Can Wear.',
          style: TextStyle(
            fontSize: 14, // Taille légèrement augmentée
            color: Colors.white,
            fontWeight: FontWeight.w300,
            height: 1.5,
            fontFamily: 'League Spartan',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
        ),
      ),
      child: SizedBox(
        width: 120, // Légèrement plus large
        child: LinearProgressIndicator(
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          borderRadius: BorderRadius.circular(10),
          minHeight: 5, // Un peu plus épais
        ),
      ),
    );
  }
}
