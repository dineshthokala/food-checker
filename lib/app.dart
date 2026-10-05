import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/logger.dart';

class FoodCheckerApp extends ConsumerWidget {
  const FoodCheckerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FoodChecker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return TalkerWrapper(
          talker: talker,
          options: const TalkerWrapperOptions(
            enableErrorAlerts: true,
            enableExceptionAlerts: true,
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
