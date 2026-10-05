import 'package:talker_flutter/talker_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global talker instance
final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    maxHistoryItems: 1000,
    useConsoleLogs: true,
  ),
);

/// Provider to access talker
final talkerProvider = Provider<Talker>((ref) => talker);

/// Log a screen-scoped error so every screen reports failures the same way.
///
/// [screen] is the screen name (e.g. 'LoginScreen'), [message] describes
/// what was being attempted, [error] is the caught error/exception.
void logScreenError(String screen, String message, Object error,
    [StackTrace? stackTrace]) {
  talker.handle(error, stackTrace, '[$screen] $message');
}

/// Log a screen-scoped warning (e.g. permission denied, validation blocked).
void logScreenWarning(String screen, String message) {
  talker.warning('[$screen] $message');
}
