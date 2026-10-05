import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final success = await ref.read(authProvider.notifier).signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      if (success) {
        final user = ref.read(authProvider).user;
        if (user != null && user.onboardingComplete) {
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      } else {
        final error = ref.read(authProvider).errorMessage ?? 'Unknown sign-in error';
        logScreenError('LoginScreen', 'Email sign-in failed', error);
      }
    } catch (e, st) {
      logScreenError('LoginScreen', 'Email sign-in threw', e, st);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email address and we will send you a link to reset your password.',
              style: TextStyle(fontSize: 14, color: AppColors.mutedPlum),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email address',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                Navigator.of(ctx).pop();
                try {
                  final success = await ref.read(authProvider.notifier).resetPassword(email);
                  if (!mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset link sent to your email.'),
                        backgroundColor: AppColors.deepTeal,
                      ),
                    );
                  } else {
                    final error = ref.read(authProvider).errorMessage ?? 'Unknown reset error';
                    logScreenError('LoginScreen', 'Password reset failed for $email', error);
                  }
                } catch (e, st) {
                  logScreenError('LoginScreen', 'Password reset threw for $email', e, st);
                }
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      final success = await ref.read(authProvider.notifier).signInWithGoogle();
      if (!mounted) return;
      if (success) {
        final user = ref.read(authProvider).user;
        if (user != null && user.onboardingComplete) {
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      } else {
        final error = ref.read(authProvider).errorMessage ?? 'Unknown Google sign-in error';
        logScreenError('LoginScreen', 'Google sign-in failed', error);
      }
    } catch (e, st) {
      logScreenError('LoginScreen', 'Google sign-in threw', e, st);
    }
  }

  // ignore: unused_element
  Future<void> _signInWithApple() async {
    try {
      final success = await ref.read(authProvider.notifier).signInWithApple();
      if (!mounted) return;
      if (success) {
        final user = ref.read(authProvider).user;
        if (user != null && user.onboardingComplete) {
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      } else {
        final error = ref.read(authProvider).errorMessage ?? 'Unknown Apple sign-in error';
        logScreenError('LoginScreen', 'Apple sign-in failed', error);
      }
    } catch (e, st) {
      logScreenError('LoginScreen', 'Apple sign-in threw', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                // Logo area
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.tealSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.deepTeal,
                    size: 30,
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                ),
                const SizedBox(height: 32),
                // Title
                Text(
                  'Welcome back',
                  style: Theme.of(context).textTheme.displayMedium,
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 8),
                Text(
                  'Sign in to check what\'s safe for you',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.mutedPlum,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                const SizedBox(height: 40),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.textLight,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your password';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                const SizedBox(height: 12),

                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _showForgotPasswordDialog,
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Error message
                if (authState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),

                // Sign in button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _signIn,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : const Text('Sign in'),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                const SizedBox(height: 24),

                // Social login
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: authState.isLoading ? null : _signInWithGoogle,
                    icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                const SizedBox(height: 40),

                // Register link
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/register'),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedPlum,
                        ),
                        children: const [
                          TextSpan(text: 'New here? '),
                          TextSpan(
                            text: 'Create account',
                            style: TextStyle(
                              color: AppColors.deepTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
