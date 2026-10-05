import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../models/food_result.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/supabase_food_decision_repository.dart';
import '../../core/utils/logger.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  File? _profileImage;
  List<FoodDecision> _decisions = [];

  @override
  void initState() {
    super.initState();
    _loadDecisions();
  }

  Future<void> _loadDecisions() async {
    try {
      final list = await ref.read(foodDecisionRepositoryProvider).getDecisions();
      if (mounted) {
        setState(() {
          _decisions = list.take(5).toList();
        });
      }
    } catch (e, st) {
      logScreenError('ProfileScreen', 'Failed to load recent food decisions', e, st);
    }
  }

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    if (status.isDenied) {
      talker.warning('Photo permission denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo permission is required to change profile picture.')),
        );
      }
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        talker.info('Profile image updated');
      }
    } catch (e, st) {
      talker.handle(e, st, 'Failed to pick image');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Header ──
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.tealSurface,
                            backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                            child: _profileImage == null
                                ? Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.deepTeal,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.deepTeal,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedPlum,
                      ),
                    ),
                    if (user.bmi != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tealSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'BMI ${user.bmi!.toStringAsFixed(1)} · ${user.bmiCategory}',
                          style: const TextStyle(
                            color: AppColors.deepTeal,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 32),

              // ── Conditions ──
              if (user.conditions.isNotEmpty) ...[
                _SectionCard(
                  title: 'My conditions',
                  icon: Icons.medical_services_outlined,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.conditions.map((c) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tealSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.deepTeal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 16),
              ],

              // ── Body Measurements ──
              _SectionCard(
                title: 'Body measurements',
                icon: Icons.straighten_rounded,
                child: Column(
                  children: [
                    _InfoRow('Age', user.age != null ? '${user.age} years' : 'Not set'),
                    _InfoRow('Gender', user.gender ?? 'Not set'),
                    _InfoRow('Height', user.heightCm != null ? '${user.heightCm!.toStringAsFixed(0)} cm' : 'Not set'),
                    _InfoRow('Weight', user.weightKg != null ? '${user.weightKg!.toStringAsFixed(0)} kg' : 'Not set'),
                    _InfoRow('Ethnicity', user.ethnicity ?? 'Not set'),
                    _InfoRow('Blood group', user.bloodGroup ?? 'Not set'),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 16),

              // ── Diet & Preferences ──
              _SectionCard(
                title: 'Diet & preferences',
                icon: Icons.restaurant_menu_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow('Diet type', user.dietType ?? 'No preference'),
                    if (user.allergies.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Allergies',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedPlum,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: user.allergies.map((a) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.verdictAvoidBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    a,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.verdictAvoid,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    if (user.medications.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Medications',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedPlum,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: user.medications.map((m) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.verdictLimitBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    m,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.verdictLimit,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const SizedBox(height: 32),

              // ── Recent Decision History ──
              if (_decisions.isNotEmpty) ...[
                _SectionCard(
                  title: 'Recent food decisions',
                  icon: Icons.history_rounded,
                  child: Column(
                    children: _decisions.map((d) {
                      final isWillEat = d.decision == 'will_eat';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                d.food,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.charcoal,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isWillEat ? AppColors.verdictLimitBg : AppColors.verdictGoodBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isWillEat ? 'Ate it' : 'Avoided',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isWillEat ? AppColors.verdictLimit : AppColors.verdictGood,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
                const SizedBox(height: 16),
              ],

              // ── Settings Section ──
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.edit_outlined,
                title: 'Edit profile',
                subtitle: 'Update your conditions and measurements',
                onTap: () {
                  context.push('/onboarding');
                },
              ).animate().fadeIn(duration: 400.ms, delay: 450.ms),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change password',
                subtitle: 'Update your login password',
                onTap: () => _showChangePasswordDialog(context),
              ).animate().fadeIn(duration: 400.ms, delay: 470.ms),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.bug_report_outlined,
                title: 'Developer logs',
                subtitle: 'View network and error logs',
                onTap: () {
                  context.push('/talker');
                },
              ).animate().fadeIn(duration: 400.ms, delay: 490.ms),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.delete_outline_rounded,
                title: 'Delete account',
                subtitle: 'Soft delete with 30-day grace period',
                isDestructive: true,
                onTap: () => _showDeleteDialog(context, ref),
              ).animate().fadeIn(duration: 400.ms, delay: 510.ms),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                subtitle: 'You can sign back in anytime',
                onTap: () => _signOut(context, ref),
              ).animate().fadeIn(duration: 400.ms, delay: 530.ms),
              const SizedBox(height: 32),

              // ── App Version ──
              Center(
                child: Text(
                  'FoodChecker v1.0.0',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your new password (at least 6 characters):',
              style: TextStyle(fontSize: 14, color: AppColors.mutedPlum),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'New password',
                prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
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
              final newPass = passController.text.trim();
              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              try {
                await FirebaseAuth.instance.currentUser
                    ?.updatePassword(newPass);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully!'),
                    backgroundColor: AppColors.deepTeal,
                  ),
                );
              } catch (e) {
                logScreenError('ProfileScreen', 'Failed to update password', e);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to update password: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e, st) {
      logScreenError('ProfileScreen', 'Failed to sign out', e, st);
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'Your account will be deactivated and scheduled for permanent removal '
          'after a 30-day grace period. You can sign back in before then to restore your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authProvider.notifier).deleteAccount();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e, st) {
                logScreenError('ProfileScreen', 'Failed to delete account', e, st);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.deepTeal),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedPlum,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.verdictAvoidBg
                : AppColors.tealSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDestructive ? AppColors.verdictAvoid : AppColors.deepTeal,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDestructive ? AppColors.verdictAvoid : AppColors.charcoal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: AppColors.textLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onTap: onTap,
      ),
    );
  }
}
