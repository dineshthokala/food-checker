import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final success = await ref.read(authProvider.notifier).register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      if (success) {
        context.go('/onboarding');
      } else {
        final error = ref.read(authProvider).errorMessage ?? 'Unknown registration error';
        logScreenError('RegisterScreen', 'Email registration failed', error);
      }
    } catch (e, st) {
      logScreenError('RegisterScreen', 'Email registration threw', e, st);
    }
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
        logScreenError('RegisterScreen', 'Google sign-in failed', error);
      }
    } catch (e, st) {
      logScreenError('RegisterScreen', 'Google sign-in threw', e, st);
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
        logScreenError('RegisterScreen', 'Apple sign-in failed', error);
      }
    } catch (e, st) {
      logScreenError('RegisterScreen', 'Apple sign-in threw', e, st);
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
                Text(
                  'Create account',
                  style: Theme.of(context).textTheme.displayMedium,
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 8),
                Text(
                  'Let\'s personalize your food safety',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.mutedPlum,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                const SizedBox(height: 40),

                // Full name
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your name';
                    return null;
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                const SizedBox(height: 16),

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
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: InputDecoration(
                    hintText: 'Password (at least 6 characters)',
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
                    if (v == null || v.isEmpty) return 'Create a password';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                const SizedBox(height: 28),

                if (authState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _register,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : const Text('Create account'),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or sign up with',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 650.ms),
                const SizedBox(height: 24),

                // Social sign-up
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
                const SizedBox(height: 32),

                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedPlum,
                        ),
                        children: const [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign in',
                            style: TextStyle(
                              color: AppColors.deepTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 750.ms),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
