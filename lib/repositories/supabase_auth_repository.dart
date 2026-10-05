import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;

  SupabaseAuthRepository(this._supabase);

  @override
  Future<UserProfile?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return await _fetchProfile(user.id);
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw Exception('Failed to sign in');
      }
      return await _fetchProfile(response.user!.id);
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<UserProfile> register(String name, String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      if (response.user == null) {
        throw Exception('Failed to register');
      }
      return await _fetchProfile(response.user!.id, name: name, email: email);
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.foodchecker://login-callback',
      );
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  @override
  Future<void> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.foodchecker://login-callback',
      );
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.foodchecker://login-callback',
      );
    } on AuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('already registered') || msg.contains('user_already_exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (msg.contains('weak password') || msg.contains('password should be at least')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }
    if (msg.contains('rate limit') || msg.contains('over_email_send_rate_limit')) {
      return 'Too many requests. Please wait a few moments before trying again.';
    }
    return e.message;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    // 1. Update basic profile info
    await _supabase.from('profiles').update({
      'display_name': profile.displayName,
      'age': profile.age,
      'gender': profile.gender,
      'height_cm': profile.heightCm,
      'weight_kg': profile.weightKg,
      'ethnicity': profile.ethnicity,
      'blood_group': profile.bloodGroup,
      'diet_type': profile.dietType,
      'onboarding_complete': profile.onboardingComplete,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', profile.id);

    // 2. Update conditions (delete existing, then insert)
    await _supabase.from('user_conditions').delete().eq('user_id', profile.id);
    if (profile.conditions.isNotEmpty) {
      await _supabase.from('user_conditions').insert(
        profile.conditions.map((c) => {'user_id': profile.id, 'condition': c}).toList()
      );
    }

    // 3. Update allergies
    await _supabase.from('user_allergies').delete().eq('user_id', profile.id);
    if (profile.allergies.isNotEmpty) {
      await _supabase.from('user_allergies').insert(
        profile.allergies.map((a) => {'user_id': profile.id, 'allergy': a}).toList()
      );
    }

    // 4. Update medications
    await _supabase.from('user_medications').delete().eq('user_id', profile.id);
    if (profile.medications.isNotEmpty) {
      await _supabase.from('user_medications').insert(
        profile.medications.map((m) => {'user_id': profile.id, 'medication': m}).toList()
      );
    }
  }

  @override
  Future<void> deleteAccount() async {
    // In Supabase, deleting a user must be done via an edge function or by calling the RPC
    // since the client cannot delete itself directly (security restriction).
    // For now, we update 'deleted_at' for a soft delete if allowed by RLS, 
    // or we'll need an RPC call. Let's do a soft delete on profiles.
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('profiles').update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      await _supabase.auth.signOut();
    }
  }

  Future<UserProfile> _fetchProfile(String userId, {String? name, String? email}) async {
    try {
      // We will fetch profile along with conditions, allergies, and medications
      final data = await _supabase
          .from('profiles')
          .select('*, user_conditions(condition), user_allergies(allergy), user_medications(medication)')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        // Fallback if profile trigger failed or hasn't run yet
        return UserProfile(
          id: userId,
          displayName: name ?? '',
          email: email ?? '',
          createdAt: DateTime.now(),
        );
      }

      final conditions = (data['user_conditions'] as List?)?.map((c) => c['condition'] as String).toList() ?? [];
      final allergies = (data['user_allergies'] as List?)?.map((a) => a['allergy'] as String).toList() ?? [];
      final medications = (data['user_medications'] as List?)?.map((m) => m['medication'] as String).toList() ?? [];

      return UserProfile(
        id: data['id'],
        displayName: data['display_name'],
        email: data['email'],
        age: data['age'],
        gender: data['gender'],
        heightCm: (data['height_cm'] as num?)?.toDouble(),
        weightKg: (data['weight_kg'] as num?)?.toDouble(),
        ethnicity: data['ethnicity'],
        bloodGroup: data['blood_group'],
        dietType: data['diet_type'],
        conditions: conditions,
        allergies: allergies,
        medications: medications,
        onboardingComplete: data['onboarding_complete'] ?? false,
        createdAt: DateTime.parse(data['created_at']),
      );
    } catch (e) {
      // In case of error (e.g. offline), we might want to throw or return a fallback
      throw Exception('Failed to fetch user profile: $e');
    }
  }
}
