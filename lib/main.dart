import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // = Initialise Firebase AVANT de lancer l'app
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalmaWear - Autism Helper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: SplashScreen(), // On va créer cet écran après
      debugShowCheckedModeBanner: false,
    );
  }
}

// 🎯 Écran temporaire pour tester Firebase
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône de validation
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 20),

            // Titre
            Text(
              'Firebase Configuré! 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),

            SizedBox(height: 15),

            // Sous-titre
            Text(
              'CalmaWear est prêt pour le développement',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 30),

            // Indicateur de chargement
            CircularProgressIndicator(color: Colors.blue),

            SizedBox(height: 20),

            // Platform info
            FutureBuilder(
              future: Future.delayed(Duration(seconds: 2)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Text(
                    'Platform: ${DefaultFirebaseOptions.currentPlatform}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  );
                }
                return SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }
}
