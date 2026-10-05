import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  void _init() {
    _checkCurrentUser();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    try {
      // Firebase is the source of truth; Supabase tables are accessed
      // with the Firebase ID token (Third-Party Auth).
      _authSubscription =
          FirebaseAuth.instance.authStateChanges().listen((fbUser) async {
        if (fbUser != null) {
          final user = await _repo.getCurrentUser();
          if (user != null && mounted) {
            state = AuthState(status: AuthStatus.authenticated, user: user);
          }
        } else {
          if (mounted) {
            state = const AuthState(status: AuthStatus.unauthenticated);
          }
        }
      });
    } catch (_) {
      // Offline or mock mode
    }
  }

  Future<void> _checkCurrentUser() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repo.getCurrentUser();
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repo.signIn(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repo.register(name, email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repo.signInWithGoogle();
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repo.signInWithApple();
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repo.resetPassword(email);
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _repo.updateProfile(profile);
    state = state.copyWith(user: profile);
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> deleteAccount() async {
    await _repo.deleteAccount();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
