import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/tokens.dart';
import 'data/settings_repo.dart';
import 'state/app_state.dart';

/// The frameless start-up window.
const Size kSplashSize = Size(560, 340);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final tokens = await DesignTokens.load();
  final settingsRepo = await SettingsRepo.open();

  const options = WindowOptions(
    size: kSplashSize,
    center: true,
    title: 'Book Oracle',
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
    skipTaskbar: false,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setResizable(false);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ProviderScope(
      overrides: [
        tokensProvider.overrideWithValue(tokens),
        settingsRepoProvider.overrideWithValue(settingsRepo),
      ],
      child: const BookOracleApp(),
    ),
  );
}
