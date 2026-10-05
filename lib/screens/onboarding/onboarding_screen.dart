import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/medical_data.dart';
import '../../core/utils/logger.dart';
import '../../models/onboarding_data.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();

  // Text controllers for step 2
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    try {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      ref.read(onboardingProvider.notifier).goToStep(step);
    } catch (e, st) {
      logScreenError('OnboardingScreen', 'Failed to go to step $step', e, st);
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final data = ref.read(onboardingProvider);
      final authNotifier = ref.read(authProvider.notifier);
      final user = ref.read(authProvider).user;

      if (user == null) {
        logScreenWarning('OnboardingScreen', 'Complete tapped but no user found');
        return;
      }

      final updatedUser = user.copyWith(
        conditions: data.conditions,
        heightCm: data.heightCm,
        weightKg: data.weightKg,
        age: data.age,
        gender: data.gender,
        ethnicity: data.ethnicity,
        bloodGroup: data.bloodGroup,
        dietType: data.dietType,
        allergies: data.allergies,
        medications: data.medications,
        onboardingComplete: true,
      );

      await authNotifier.updateProfile(updatedUser);

      if (mounted) {
        final error = ref.read(authProvider).errorMessage;
        if (error != null) {
          logScreenError('OnboardingScreen', 'Failed to save onboarding profile', error);
          return;
        }
        context.go('/home');
      }
    } catch (e, st) {
      logScreenError('OnboardingScreen', 'Failed to complete onboarding', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (data.currentStep > 0)
                        GestureDetector(
                          onTap: () => _goToStep(data.currentStep - 1),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.charcoal,
                          ),
                        )
                      else
                        const SizedBox(width: 24),
                      Text(
                        'Step ${data.currentStep + 1} of ${OnboardingData.totalSteps}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress indicator
                  Row(
                    children: List.generate(OnboardingData.totalSteps, (i) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(
                            right: i < OnboardingData.totalSteps - 1 ? 6 : 0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: i <= data.currentStep
                                ? AppColors.deepTeal
                                : AppColors.divider,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) {
                  ref.read(onboardingProvider.notifier).goToStep(i);
                },
                children: [
                  _ConditionsStep(data: data),
                  _BodyPersonalStep(
                    data: data,
                    heightController: _heightController,
                    weightController: _weightController,
                    ageController: _ageController,
                  ),
                  _DietAllergiesStep(data: data),
                  _ConsentStep(data: data),
                ],
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: data.canProceedFromStep
                      ? () {
                          if (data.currentStep < OnboardingData.totalSteps - 1) {
                            _goToStep(data.currentStep + 1);
                          } else {
                            _completeOnboarding();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: data.canProceedFromStep
                        ? AppColors.deepTeal
                        : AppColors.divider,
                  ),
                  child: Text(
                    data.currentStep < OnboardingData.totalSteps - 1
                        ? 'Continue'
                        : 'Get started',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1: Medical Conditions
// ─────────────────────────────────────────────────────────────────────────────

class _ConditionsStep extends ConsumerWidget {
  final OnboardingData data;
  const _ConditionsStep({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What conditions\nare you managing?',
            style: Theme.of(context).textTheme.displayMedium,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Select all that apply. This helps us check foods against your needs.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedPlum,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: MedicalData.conditions.map((condition) {
              final selected = data.conditions.contains(condition);
              return FilterChip(
                label: Text(condition),
                selected: selected,
                onSelected: (_) {
                  ref.read(onboardingProvider.notifier).toggleCondition(condition);
                },
                selectedColor: AppColors.tealSurface,
                checkmarkColor: AppColors.deepTeal,
                side: BorderSide(
                  color: selected ? AppColors.deepTeal : AppColors.divider,
                  width: selected ? 1.5 : 1,
                ),
                labelStyle: TextStyle(
                  color: selected ? AppColors.deepTeal : AppColors.charcoal,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2: Body & Personal
// ─────────────────────────────────────────────────────────────────────────────

class _BodyPersonalStep extends ConsumerWidget {
  final OnboardingData data;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController ageController;

  const _BodyPersonalStep({
    required this.data,
    required this.heightController,
    required this.weightController,
    required this.ageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about\nyourself',
            style: Theme.of(context).textTheme.displayMedium,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'This helps personalize food recommendations to your body.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedPlum,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 28),

          // Age
          TextFormField(
            controller: ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Age',
              prefixIcon: Icon(Icons.cake_outlined, size: 20),
            ),
            onChanged: (v) {
              final age = int.tryParse(v);
              notifier.setAge(age);
            },
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 16),

          // Gender
          DropdownButtonFormField<String>(
            initialValue: data.gender,
            decoration: const InputDecoration(
              hintText: 'Gender',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
            items: MedicalData.genders.map((g) {
              return DropdownMenuItem(value: g, child: Text(g));
            }).toList(),
            onChanged: (v) => notifier.setGender(v),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 16),

          // Height & Weight
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Height (cm)',
                    prefixIcon: Icon(Icons.height_rounded, size: 20),
                  ),
                  onChanged: (v) {
                    notifier.setHeight(double.tryParse(v));
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Weight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20),
                  ),
                  onChanged: (v) {
                    notifier.setWeight(double.tryParse(v));
                  },
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
          const SizedBox(height: 16),

          // Ethnicity
          DropdownButtonFormField<String>(
            initialValue: data.ethnicity,
            decoration: const InputDecoration(
              hintText: 'Ethnicity',
              prefixIcon: Icon(Icons.language_rounded, size: 20),
            ),
            items: MedicalData.ethnicities.map((e) {
              return DropdownMenuItem(value: e, child: Text(e));
            }).toList(),
            onChanged: (v) => notifier.setEthnicity(v),
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
          const SizedBox(height: 16),

          // Blood group
          DropdownButtonFormField<String>(
            initialValue: data.bloodGroup,
            decoration: const InputDecoration(
              hintText: 'Blood group (optional)',
              prefixIcon: Icon(Icons.bloodtype_outlined, size: 20),
            ),
            items: MedicalData.bloodGroups.map((b) {
              return DropdownMenuItem(value: b, child: Text(b));
            }).toList(),
            onChanged: (v) => notifier.setBloodGroup(v),
          ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3: Diet, Allergies & Medications
// ─────────────────────────────────────────────────────────────────────────────

class _DietAllergiesStep extends ConsumerWidget {
  final OnboardingData data;
  const _DietAllergiesStep({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diet, allergies\n& medications',
            style: Theme.of(context).textTheme.displayMedium,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'These affect what\'s safe for you. Skip any that don\'t apply.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedPlum,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 28),

          // Diet type
          Text(
            'Food diet type',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: MedicalData.dietTypes.map((diet) {
              final selected = data.dietType == diet;
              return ChoiceChip(
                label: Text(diet),
                selected: selected,
                onSelected: (_) => notifier.setDietType(diet),
                selectedColor: AppColors.tealSurface,
                side: BorderSide(
                  color: selected ? AppColors.deepTeal : AppColors.divider,
                  width: selected ? 1.5 : 1,
                ),
                labelStyle: TextStyle(
                  color: selected ? AppColors.deepTeal : AppColors.charcoal,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 28),

          // Allergies
          Text(
            'Known allergies',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: MedicalData.allergies.map((allergy) {
              final selected = data.allergies.contains(allergy);
              return FilterChip(
                label: Text(allergy),
                selected: selected,
                onSelected: (_) => notifier.toggleAllergy(allergy),
                selectedColor: AppColors.verdictAvoidBg,
                checkmarkColor: AppColors.verdictAvoid,
                side: BorderSide(
                  color: selected ? AppColors.verdictAvoid : AppColors.divider,
                  width: selected ? 1.5 : 1,
                ),
                labelStyle: TextStyle(
                  color: selected ? AppColors.verdictAvoid : AppColors.charcoal,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 28),

          // Medications
          Text(
            'Current medications',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: MedicalData.medications.map((med) {
              final selected = data.medications.contains(med);
              return FilterChip(
                label: Text(med),
                selected: selected,
                onSelected: (_) => notifier.toggleMedication(med),
                selectedColor: AppColors.verdictLimitBg,
                checkmarkColor: AppColors.verdictLimit,
                side: BorderSide(
                  color: selected ? AppColors.verdictLimit : AppColors.divider,
                  width: selected ? 1.5 : 1,
                ),
                labelStyle: TextStyle(
                  color: selected ? AppColors.verdictLimit : AppColors.charcoal,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4: Consent & Privacy
// ─────────────────────────────────────────────────────────────────────────────

class _ConsentStep extends ConsumerWidget {
  final OnboardingData data;
  const _ConsentStep({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Almost there',
            style: Theme.of(context).textTheme.displayMedium,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'We take your health data seriously. Please review and accept.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedPlum,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 32),

          // Health data consent
          _ConsentTile(
            icon: Icons.health_and_safety_outlined,
            title: 'Health data consent',
            subtitle:
                'I understand that my health information is stored securely '
                'and used only to personalize food recommendations.',
            value: data.consentGiven,
            onChanged: (v) => notifier.setConsent(v ?? false),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 16),

          // Privacy policy
          _ConsentTile(
            icon: Icons.shield_outlined,
            title: 'Privacy policy',
            subtitle:
                'I have read and accept the Privacy Policy. My data will not '
                'be shared with third parties without my consent.',
            value: data.privacyAccepted,
            onChanged: (v) => notifier.setPrivacy(v ?? false),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 28),

          // Disclaimer card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.verdictLimitBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.verdictLimit,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'FoodChecker provides general food guidance based on your '
                    'profile. It is not a substitute for professional medical '
                    'advice, diagnosis, or treatment. Always consult your '
                    'doctor or dietitian before making dietary changes.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.charcoal.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _ConsentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppColors.deepTeal : AppColors.divider,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.deepTeal, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.deepTeal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
