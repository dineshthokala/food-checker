import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logger.dart';

class NetworkMonitor {
  static void init() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        talker.warning('Network connectivity lost. App is now offline.');
      } else {
        talker.info('Network connected: $results');
      }
    });
  }
}

final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final initial = await Connectivity().checkConnectivity();
  yield !initial.contains(ConnectivityResult.none);

  yield* Connectivity().onConnectivityChanged.map((results) {
    return !results.contains(ConnectivityResult.none);
  });
});
