import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/utils/offline_db.dart';
import 'core/utils/logger.dart';
import 'core/utils/network_monitor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline local database
  await OfflineDB.init();

  // Monitor network status
  NetworkMonitor.init();

  // Firebase is the auth source of truth (Option A).
  // Config lives in lib/firebase_options.dart (flutterfire-style).
  // Android uses google-services.json values; add iOS/Web there when needed.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Supabase Postgres is accessed with the Firebase ID token
  // (Dashboard > Auth > Third-Party Auth > Firebase).
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
    accessToken: () async {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    },
  );

  // One-time cleanup of legacy Supabase Auth sessions from before migration.
  // Fresh installs: no-op. Existing users re-login via Firebase (matched by email).
  try {
    if (FirebaseAuth.instance.currentUser == null &&
        Supabase.instance.client.auth.currentSession != null) {
      await Supabase.instance.client.auth.signOut();
    }
  } catch (_) {}

  // Handle unhandled synchronous & asynchronous errors with Talker
  FlutterError.onError = (details) => talker.handle(details.exception, details.stack, 'FlutterError');
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack, 'AsyncError');
    return true;
  };

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: FoodCheckerApp()));
}
