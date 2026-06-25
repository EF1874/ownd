import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/navigation/app_router.dart';
import 'data/services/preferences_service.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(prefs);

  final container = ProviderContainer(
    overrides: [
      preferencesServiceProvider.overrideWithValue(preferencesService),
    ],
  );

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_runStartupTasks(container));
  });
}

Future<void> _runStartupTasks(ProviderContainer container) async {
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e) {
    debugPrint('Error setting high refresh rate: $e');
  }

  try {
    await container.read(notificationServiceProvider).init();
  } catch (e) {
    debugPrint('Notification Init Error: $e');
  }

  try {
    await container
        .read(subscriptionServiceProvider)
        .checkStartupSubscriptions();
  } catch (e) {
    debugPrint('Subscription Renewal Error: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: '物记',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CH'), Locale('en', 'US')],
    );
  }
}
