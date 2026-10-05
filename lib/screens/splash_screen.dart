import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../core/utils/logger.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    talker.info('Splash screen initialized');
    _navigate();
  }

  Future<void> _navigate() async {
    try {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;

      var auth = ref.read(authProvider);
      if (!auth.isAuthenticated) {
        // Firebase stream may lag a frame behind; wait briefly for profile sync.
        for (int i = 0; i < 15; i++) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (!mounted) return;
          auth = ref.read(authProvider);
          if (auth.isAuthenticated) break;
        }
      }

      if (auth.isAuthenticated) {
        final user = auth.user;
        if (user != null && user.onboardingComplete) {
          _goTo('/home');
        } else {
          _goTo('/onboarding');
        }
      } else {
        _goTo('/login');
      }
    } catch (e, st) {
      logScreenError('SplashScreen', 'Failed to navigate from splash', e, st);
      _goTo('/login');
    }
  }

  void _goTo(String path) {
    if (mounted) {
      context.go(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepTeal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon
            Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.eco_rounded,
                          size: 64,
                          color: AppColors.white,
                        );
                      },
                    ),
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 28),
            // App name
            const Text(
                  'FoodChecker',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    letterSpacing: -0.5,
                  ),
                )
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0, duration: 500.ms),
            const SizedBox(height: 8),
            // Tagline
            Text(
              'Eat right for your health',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.white.withValues(alpha: 0.75),
              ),
            ).animate(delay: 600.ms).fadeIn(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
