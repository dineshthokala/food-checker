import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase config for foodchecker-673b7.
/// Generated values from google-services.json (Android).
/// iOS / Web: re-run `flutterfire configure` or paste values from the
/// Firebase console once those apps are added.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions: Web not configured yet. '
        'Run `flutterfire configure` or add Web app values here.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions: iOS not configured yet. '
          'Add GoogleService-Info.plist + iOS values here.',
        );
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions: desktop not configured.',
        );
      default:
        throw UnsupportedError('Unknown platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBliG3Q9sjEsgy1fcMZQS4yt8uLO6Gnt3I',
    appId: '1:669610215785:android:d3f0f7cc9aa73342bed5f8',
    messagingSenderId: '669610215785',
    projectId: 'foodchecker-673b7',
    storageBucket: 'foodchecker-673b7.firebasestorage.app',
  );
}
