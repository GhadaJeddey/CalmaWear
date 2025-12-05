import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';
import 'home_shell.dart';
import '../screens/splash_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/home_screen.dart';
import '../screens/planner/planner_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/dashboard/notifications_screen.dart';
import '../screens/chat/chat_history_screen.dart';
import '../screens/profile/parent_profile.dart';
import '../screens/profile/child_profile.dart';
import '../screens/test/monitoring_test_screen.dart';

// Navigator keys
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _plannerNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'planner');
final _communityNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'community',
);
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.splash,
  routes: [
    // Auth routes (outside shell)
    GoRoute(
      path: Routes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.welcome,
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: Routes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: Routes.signup,
      name: 'signup',
      builder: (context, state) => const SignupScreen(),
    ),

    // Child profile setup after signup (outside shell)
    GoRoute(
      path: Routes.childProfileSetup,
      name: 'child-profile-setup',
      builder: (context, state) => const ChildProfileScreen(isSetupMode: true),
    ),

    // Test route (outside shell)
    GoRoute(
      path: Routes.testMonitoring,
      name: 'test-monitoring',
      builder: (context, state) => const MonitoringTestScreen(),
    ),

    // Chat route (outside shell - no bottom nav)
    GoRoute(
      path: Routes.chat,
      name: 'chat',
      builder: (context, state) => const ChatScreen(),
      routes: [
        GoRoute(
          path: 'history',
          name: 'chat-history',
          builder: (context, state) => const ConversationHistoryScreen(),
        ),
      ],
    ),

    // Main app shell with bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomeShell(navigationShell: navigationShell);
      },
      branches: [
        // BRANCH 0: HOME
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: Routes.home,
              name: 'home',
              builder: (context, state) => const HomeScreen(),
              routes: [
                // Nested routes for home
                GoRoute(
                  path: 'notifications',
                  name: 'notifications',
                  builder: (context, state) => const NotificationsScreen(),
                ),
              ],
            ),
          ],
        ),

        // BRANCH 1: PLANNER
        StatefulShellBranch(
          navigatorKey: _plannerNavigatorKey,
          routes: [
            GoRoute(
              path: Routes.planner,
              name: 'planner',
              builder: (context, state) => const PlannerScreen(),
            ),
          ],
        ),

        // BRANCH 2: COMMUNITY
        StatefulShellBranch(
          navigatorKey: _communityNavigatorKey,
          routes: [
            GoRoute(
              path: Routes.community,
              name: 'community',
              builder: (context, state) => const CommunityScreen(),
            ),
          ],
        ),

        // BRANCH 3: PROFILE
        StatefulShellBranch(
          navigatorKey: _profileNavigatorKey,
          routes: [
            GoRoute(
              path: Routes.profile,
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'parent',
                  name: 'parent-profile',
                  builder: (context, state) => const ParentProfileScreen(),
                ),
                GoRoute(
                  path: 'child',
                  name: 'child-profile',
                  builder: (context, state) => const ChildProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
