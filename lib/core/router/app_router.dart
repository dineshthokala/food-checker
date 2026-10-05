
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../utils/logger.dart';
import '../../screens/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/result/result_screen.dart';
import '../../screens/safe_foods/safe_foods_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/shell/app_shell.dart';
import '../../screens/scanner/scanner_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    observers: [TalkerRouteObserver(talker)],
    onException: (context, state, router) {
      talker.info('GoRouter handling exception for: ${state.uri}');
      router.go('/login');
    },
    routes: [
      GoRoute(
        path: '/login-callback',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/talker',
        builder: (context, state) => TalkerScreen(talker: talker),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Main app shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/safe-foods',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SafeFoodsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      // Result screen (outside shell — no bottom nav)
      GoRoute(
        path: '/result/:food',
        builder: (context, state) {
          final food = Uri.decodeComponent(
            state.pathParameters['food'] ?? '',
          );
          return ResultScreen(food: food);
        },
      ),
    ],
  );
});
