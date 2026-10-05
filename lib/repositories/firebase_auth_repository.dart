import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide OAuthProvider, User;
import '../models/user_profile.dart';
import 'auth_repository.dart';

/// Option A: Firebase Auth for sign-in + Supabase Postgres for user details.
///
/// Supabase is initialized with `accessToken: Firebase ID token`
/// (Third-Party Auth), so all `from('profiles')` calls below are
/// authenticated by Firebase JWTs. `profiles.id` stores the Firebase UID.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository(this._auth, this._supabase)
      : _googleSignIn = GoogleSignIn();

  @override
  Future<UserProfile?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    try {
      return await _fetchProfile(fbUser.uid,
          email: fbUser.email, name: fbUser.displayName);
    } catch (_) {
      // Offline: return minimal profile so splash can still route.
      return UserProfile(
        id: fbUser.uid,
        displayName: fbUser.displayName ?? fbUser.email?.split('@').first ?? '',
        email: fbUser.email ?? '',
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = cred.user;
      if (fbUser == null) throw Exception('Failed to sign in');
      return await _fetchOrCreateProfile(fbUser);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  @override
  Future<UserProfile> register(String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = cred.user;
      if (fbUser == null) throw Exception('Failed to register');
      await fbUser.updateDisplayName(name);
      await fbUser.reload();
      final refreshed = _auth.currentUser ?? fbUser;
      return await _fetchOrCreateProfile(refreshed, name: name);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      if (cred.user == null) throw Exception('Google sign-in failed');
      // Profile row is ensured here; auth_provider stream picks up the user.
      await _fetchOrCreateProfile(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Google sign-in failed: $e');
    }
  }

  @override
  Future<void> signInWithApple() async {
    try {
      final appleProvider = OAuthProvider('apple.com')
        ..addScope('email')
        ..addScope('name');
      final cred = await _auth.signInWithProvider(appleProvider);
      if (cred.user == null) throw Exception('Apple sign-in failed');
      await _fetchOrCreateProfile(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut().catchError((_) => null);
    await _auth.signOut();
    // Clear any legacy Supabase Auth session from before the migration.
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
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

    await _supabase.from('user_conditions').delete().eq('user_id', profile.id);
    if (profile.conditions.isNotEmpty) {
      await _supabase.from('user_conditions').insert(
        profile.conditions.map((c) => {'user_id': profile.id, 'condition': c}).toList()
      );
    }

    await _supabase.from('user_allergies').delete().eq('user_id', profile.id);
    if (profile.allergies.isNotEmpty) {
      await _supabase.from('user_allergies').insert(
        profile.allergies.map((a) => {'user_id': profile.id, 'allergy': a}).toList()
      );
    }

    await _supabase.from('user_medications').delete().eq('user_id', profile.id);
    if (profile.medications.isNotEmpty) {
      await _supabase.from('user_medications').insert(
        profile.medications.map((m) => {'user_id': profile.id, 'medication': m}).toList()
      );
    }
  }

  @override
  Future<void> deleteAccount() async {
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      try {
        await _supabase.from('profiles').update({
          'deleted_at': DateTime.now().toIso8601String(),
        }).eq('id', fbUser.uid);
      } catch (_) {}
      try {
        await fbUser.delete();
      } catch (_) {
        // Requires recent login — fall back to sign out so UI still resets.
      }
    }
    await signOut();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in instead.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many requests. Please wait a few moments before trying again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<UserProfile> _fetchOrCreateProfile(User fbUser, {String? name}) async {
    final existing = await _fetchProfile(fbUser.uid,
        email: fbUser.email, name: name ?? fbUser.displayName);
    // _fetchProfile returns a fallback when row is missing — ensure row exists.
    try {
      final row = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', fbUser.uid)
          .maybeSingle();
      if (row == null) {
        await _supabase.from('profiles').insert({
          'id': fbUser.uid,
          'email': fbUser.email ?? '',
          'display_name': name ??
              fbUser.displayName ??
              (fbUser.email?.split('@').first ?? ''),
        });
        return await _fetchProfile(fbUser.uid,
            email: fbUser.email, name: name ?? fbUser.displayName);
      }
    } catch (_) {
      // RLS / offline — return what we have.
    }
    return existing;
  }

  Future<UserProfile> _fetchProfile(String uid, {String? email, String? name}) async {
    final data = await _supabase
        .from('profiles')
        .select('*, user_conditions(condition), user_allergies(allergy), user_medications(medication)')
        .eq('id', uid)
        .maybeSingle();

    if (data == null) {
      return UserProfile(
        id: uid,
        displayName: name ?? email?.split('@').first ?? '',
        email: email ?? '',
        createdAt: DateTime.now(),
      );
    }

    final conditions =
        (data['user_conditions'] as List?)?.map((c) => c['condition'] as String).toList() ?? [];
    final allergies =
        (data['user_allergies'] as List?)?.map((a) => a['allergy'] as String).toList() ?? [];
    final medications =
        (data['user_medications'] as List?)?.map((m) => m['medication'] as String).toList() ?? [];

    return UserProfile(
      id: data['id'] as String,
      displayName: (data['display_name'] as String?) ?? name ?? '',
      email: (data['email'] as String?) ?? email ?? '',
      age: data['age'] as int?,
      gender: data['gender'] as String?,
      heightCm: (data['height_cm'] as num?)?.toDouble(),
      weightKg: (data['weight_kg'] as num?)?.toDouble(),
      ethnicity: data['ethnicity'] as String?,
      bloodGroup: data['blood_group'] as String?,
      dietType: data['diet_type'] as String?,
      conditions: conditions,
      allergies: allergies,
      medications: medications,
      onboardingComplete: (data['onboarding_complete'] as bool?) ?? false,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
    );
  }
}
