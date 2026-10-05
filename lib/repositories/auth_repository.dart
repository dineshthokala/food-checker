import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';
import 'firebase_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> signIn(String email, String password);
  Future<UserProfile> register(String name, String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> resetPassword(String email);
  Future<void> signOut();
  Future<void> updateProfile(UserProfile profile);
  Future<void> deleteAccount();
}

/// Mock auth that persists to FlutterSecureStorage for secure offline storage.
class MockAuthRepository implements AuthRepository {
  static const _userKey = 'fc_current_user_secure';
  final _storage = const FlutterSecureStorage();

  @override
  Future<UserProfile?> getCurrentUser() async {
    final json = await _storage.read(key: _userKey);
    if (json == null) return null;
    return UserProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Check if user exists in secure storage
    final json = await _storage.read(key: _userKey);
    if (json != null) {
      final profile = UserProfile.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      if (profile.email == email) return profile;
    }

    // Mock: accept any email/password, create or return user
    final profile = UserProfile(
      id: email.hashCode.toRadixString(16),
      displayName: email.split('@').first,
      email: email,
      createdAt: DateTime.now(),
    );
    await _storage.write(key: _userKey, value: jsonEncode(profile.toJson()));
    return profile;
  }

  @override
  Future<UserProfile> register(
    String name,
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final profile = UserProfile(
      id: email.hashCode.toRadixString(16),
      displayName: name,
      email: email,
      createdAt: DateTime.now(),
    );
    await _storage.write(key: _userKey, value: jsonEncode(profile.toJson()));
    return profile;
  }

  @override
  Future<void> signInWithGoogle() async {
    await signIn('google_user@example.com', 'password123');
  }

  @override
  Future<void> signInWithApple() async {
    await signIn('apple_user@example.com', 'password123');
  }

  @override
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> signOut() async {
    await _storage.delete(key: _userKey);
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await _storage.write(key: _userKey, value: jsonEncode(profile.toJson()));
  }

  @override
  Future<void> deleteAccount() async {
    await _storage.deleteAll();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Option A: Firebase Auth + Supabase tables (Third-Party Auth).
  return FirebaseAuthRepository(
    FirebaseAuth.instance,
    Supabase.instance.client,
  );
});
