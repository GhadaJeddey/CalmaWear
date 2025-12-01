import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard/home_screen.dart';
import 'screens/test/monitoring_test_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/chat/chat_history_screen.dart';
import 'providers/monitoring_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/planner/planner_screen.dart';
import 'screens/community/community_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'providers/planner_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MonitoringProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PlannerProvider()),
      ],
      child: MaterialApp(
        title: 'CalmaWear',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/test-monitoring': (context) => const MonitoringTestScreen(),
          '/chat': (context) => const ChatScreen(),
          '/chat-history': (context) => const ConversationHistoryScreen(),
          '/planner': (context) => const PlannerScreen(),
          '/community': (context) => const CommunityScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
