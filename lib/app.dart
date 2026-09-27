import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'core/tokens.dart';
import 'data/models.dart';
import 'data/sheet_link.dart';
import 'data/settings_repo.dart';
import 'state/app_state.dart';
import 'state/deal_state.dart';
import 'state/library_state.dart';
import 'state/onboarding_state.dart';
import 'ui/deal/deal_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/splash/splash_screen.dart';

/// Minimum splash time, so the card fan finishes its run.
const Duration kMinSplash = Duration(milliseconds: 1600);

/// Cross-fade from the splash window into the main one.
const Duration kWindowFade = Duration(milliseconds: 400);

const Size kMinWindowSize = Size(1280, 720);
const Size kDefaultWindowSize = Size(1536, 864);

class BookOracleApp extends ConsumerWidget {
  const BookOracleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(deckThemeProvider);
    return MaterialApp(
      title: 'Book Oracle',
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: const Duration(milliseconds: 400),
      theme: themeForDeck(deck),
      // Without a Material ancestor every Text inherits the framework's
      // fallback style — which carries a double underline.
      home: Material(
        color: deck.bg,
        child: const AppRouter(),
      ),
    );
  }
}

ThemeData themeForDeck(DeckTheme d) {
  final brightness = d.dark ? Brightness.dark : Brightness.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: d.bg,
    canvasColor: d.surface,
    fontFamily: d.bodyFont,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: d.accent,
      onPrimary: d.accentInk,
      secondary: d.accent,
      onSecondary: d.accentInk,
      error: d.error,
      onError: d.accentInk,
      surface: d.surface,
      onSurface: d.text,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: d.accent,
      selectionColor: d.accentSoft,
      selectionHandleColor: d.accent,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll<Color>(d.line2),
      thickness: const WidgetStatePropertyAll<double>(6),
      radius: const Radius.circular(3),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: d.surface2,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: d.body(size: 12),
    ),
    extensions: <ThemeExtension<dynamic>>[d],
  );
}

/// Owns start-up, the splash → main window hand-off, and window persistence.
class AppRouter extends ConsumerStatefulWidget {
  const AppRouter({super.key});

  @override
  ConsumerState<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<AppRouter>
    with WindowListener, WidgetsBindingObserver {
  String _splashText = '';
  bool _booted = false;
  Timer? _rememberDebounce;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _rememberDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  // --- window persistence --------------------------------------------------

  /// window_manager only reports `resized` when the user finishes dragging an
  /// edge, so snapped and programmatic resizes would go unrecorded. Flutter's
  /// own metrics callback catches every one of them.
  @override
  void didChangeMetrics() => _scheduleRemember();

  @override
  void onWindowResized() => _scheduleRemember();

  @override
  void onWindowMoved() => _scheduleRemember();

  @override
  void onWindowMaximize() => _scheduleRemember();

  @override
  void onWindowUnmaximize() => _scheduleRemember();

  void _scheduleRemember() {
    _rememberDebounce?.cancel();
    _rememberDebounce =
        Timer(const Duration(milliseconds: 400), _rememberWindow);
  }

  Future<void> _rememberWindow() async {
    if (!_booted) return;
    final settings = ref.read(settingsProvider);
    if (!settings.rememberWindow) return;
    try {
      final maximized = await windowManager.isMaximized();
      // A maximized window would otherwise overwrite the restore geometry.
      if (maximized) {
        final saved = settings.window ?? WindowPlacement.fallback;
        ref.read(settingsProvider.notifier).setWindow(WindowPlacement(
              width: saved.width,
              height: saved.height,
              x: saved.x,
              y: saved.y,
              maximized: true,
            ));
        return;
      }
      final size = await windowManager.getSize();
      final position = await windowManager.getPosition();
      ref.read(settingsProvider.notifier).setWindow(WindowPlacement(
            width: size.width,
            height: size.height,
            x: position.dx,
            y: position.dy,
            maximized: false,
          ));
    } catch (_) {}
  }

  // --- start-up ------------------------------------------------------------

  Future<void> _boot() async {
    final clock = Stopwatch()..start();
    final s = ref.read(stringsProvider);
    setState(() => _splashText = s.splashLoading);

    final settings = ref.read(settingsProvider);
    final cache = ref.read(cacheRepoProvider);
    final library = ref.read(libraryProvider.notifier);
    final onboarding = ref.read(onboardingProvider.notifier);
    var next = AppRoute.onboarding;

    final url = settings.sheetUrl;
    final link = url == null ? null : parseSheetLink(url);

    if (url == null) {
      if (mounted) setState(() => _splashText = s.splashFirstRun);
    } else if (link == null) {
      onboarding.prefill(url);
    } else {
      LibraryData? loaded;
      SheetFailure? failure;

      Future<LibraryData?> fromNetwork() async {
        try {
          return await ref
              .read(sheetLoaderProvider)
              .load(link, originalUrl: url);
        } on SheetException catch (e) {
          failure = e.kind;
          return null;
        } catch (_) {
          failure = SheetFailure.unknown;
          return null;
        }
      }

      if (settings.refreshOnStart) {
        loaded = await fromNetwork();
      } else {
        final cached = await cache.read();
        if (cached != null) {
          library.adopt(cached, cache: false);
          next = AppRoute.deal;
        } else {
          loaded = await fromNetwork();
        }
      }

      if (loaded != null) {
        library.adopt(loaded);
        next = AppRoute.deal;
      } else if (next != AppRoute.deal) {
        if (failure == SheetFailure.network && settings.useCacheOffline) {
          final cached = await cache.read();
          if (cached != null) {
            if (mounted) setState(() => _splashText = s.splashCached);
            library.adoptCached(cached);
            next = AppRoute.deal;
          } else {
            onboarding.prefill(url);
            onboarding.showOffline();
          }
        } else {
          // A closed sheet or a broken header is fixed on the connect screen.
          onboarding.prefill(url);
          if (failure != null) await onboarding.connect(url);
        }
      }
    }

    if (next == AppRoute.deal) {
      final unread = ref.read(libraryProvider).data?.unread ?? const <Book>[];
      // The first spread lands while the splash is still up — no sound.
      ref.read(dealProvider.notifier).deal(unread, silent: true);
    }

    final remaining = kMinSplash - clock.elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    if (!mounted) return;

    await _openMainWindow();
    if (!mounted) return;
    _booted = true;
    ref.read(routeProvider.notifier).go(next);
  }

  Future<void> _openMainWindow() async {
    final settings = ref.read(settingsProvider);
    try {
      await windowManager.setResizable(true);
      await windowManager.setMinimumSize(kMinWindowSize);
      final saved = settings.rememberWindow ? settings.window : null;
      if (saved != null) {
        await windowManager.setSize(Size(
          saved.width.clamp(kMinWindowSize.width, 10000),
          saved.height.clamp(kMinWindowSize.height, 10000),
        ));
        if (saved.x != null && saved.y != null) {
          await windowManager.setPosition(Offset(saved.x!, saved.y!));
        } else {
          await windowManager.center();
        }
        if (saved.maximized) await windowManager.maximize();
      } else {
        await windowManager.setSize(kDefaultWindowSize);
        await windowManager.center();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final route = ref.watch(routeProvider);
    final s = ref.watch(stringsProvider);

    // Keep the OS window title in step with the screen.
    final title = switch (route) {
      AppRoute.settings => 'Book Oracle | ${s.settingsTitle}',
      _ => 'Book Oracle',
    };
    unawaitedSetTitle(title);

    return AnimatedSwitcher(
      duration: kWindowFade,
      child: switch (route) {
        AppRoute.splash => SplashScreen(
            key: const ValueKey<String>('splash'),
            statusText: _splashText,
          ),
        AppRoute.onboarding =>
          const OnboardingScreen(key: ValueKey<String>('onboarding')),
        AppRoute.deal => const DealScreen(key: ValueKey<String>('deal')),
        AppRoute.settings =>
          const SettingsScreen(key: ValueKey<String>('settings')),
      },
    );
  }

  String? _lastTitle;

  void unawaitedSetTitle(String title) {
    if (_lastTitle == title) return;
    _lastTitle = title;
    try {
      windowManager.setTitle(title);
    } catch (_) {}
  }
}
