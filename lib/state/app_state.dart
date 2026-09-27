import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sound.dart';
import '../core/tokens.dart';
import '../data/cache_repo.dart';
import '../data/sheet_loader.dart';
import '../data/settings_repo.dart';
import '../l10n/strings.dart';

/// Screens the app can be on.
enum AppRoute { splash, onboarding, deal, settings }

/// Overridden in `main()` once the asset is parsed.
final tokensProvider = Provider<DesignTokens>((ref) {
  throw StateError('tokensProvider must be overridden');
});

/// Overridden in `main()` once shared_preferences is open.
final settingsRepoProvider = Provider<SettingsRepo>((ref) {
  throw StateError('settingsRepoProvider must be overridden');
});

final cacheRepoProvider = Provider<CacheRepo>((ref) => const CacheRepo());

final soundBoardProvider = Provider<SoundBoard>((ref) {
  final board = SoundBoard();
  ref.onDispose(board.dispose);
  return board;
});

/// Plays [sfx] when the feature is switched on for the build and the user has
/// card sounds enabled.
void playSfx(Ref ref, Sfx sfx) {
  if (!kCardSoundsEnabled) return;
  if (!ref.read(settingsProvider).sounds) return;
  ref.read(soundBoardProvider).play(sfx);
}

final sheetLoaderProvider = Provider<SheetLoader>((ref) {
  final loader = SheetLoader();
  ref.onDispose(loader.close);
  return loader;
});

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepoProvider).read();

  void _apply(AppSettings next) {
    state = next;
    // Persisting is fire-and-forget: the in-memory value is the source of
    // truth for the running app.
    ref.read(settingsRepoProvider).write(next);
  }

  void setDeck(String id) => _apply(state.copyWith(deck: id));
  void setBackground(String id) => _apply(state.copyWith(background: id));
  void setDim(int v) => _apply(state.copyWith(dim: v.clamp(0, 80)));
  void setLanguage(String code) => _apply(state.copyWith(language: code));
  void setSeasonal(bool v) => _apply(state.copyWith(seasonalBackground: v));
  void setRefreshOnStart(bool v) => _apply(state.copyWith(refreshOnStart: v));
  void setUseCacheOffline(bool v) => _apply(state.copyWith(useCacheOffline: v));
  void setAnimations(bool v) => _apply(state.copyWith(animations: v));
  void setSounds(bool v) => _apply(state.copyWith(sounds: v));
  void setFullscreenReveal(bool v) => _apply(state.copyWith(fullscreenReveal: v));
  void setRememberWindow(bool v) => _apply(state.copyWith(rememberWindow: v));
  void setSheetUrl(String? url) => _apply(
      url == null ? state.copyWith(clearSheetUrl: true) : state.copyWith(sheetUrl: url));
  void setCustomBackground(String path) =>
      _apply(state.copyWith(customBackgroundPath: path, background: 'custom'));
  void setWindow(WindowPlacement w) => _apply(state.copyWith(window: w));
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final stringsProvider = Provider<Strings>(
    (ref) => Strings.of(ref.watch(settingsProvider.select((s) => s.language))));

final deckThemeProvider = Provider<DeckTheme>((ref) => ref
    .watch(tokensProvider)
    .deck(ref.watch(settingsProvider.select((s) => s.deck))));

class RouteNotifier extends Notifier<AppRoute> {
  @override
  AppRoute build() => AppRoute.splash;

  void go(AppRoute route) => state = route;
}

final routeProvider = NotifierProvider<RouteNotifier, AppRoute>(RouteNotifier.new);
