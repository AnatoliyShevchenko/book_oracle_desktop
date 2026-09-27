import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class WindowPlacement {
  const WindowPlacement({
    required this.width,
    required this.height,
    this.x,
    this.y,
    this.maximized = false,
  });

  final double width;
  final double height;
  final double? x;
  final double? y;
  final bool maximized;

  static const WindowPlacement fallback =
      WindowPlacement(width: 1536, height: 864);
}

@immutable
class AppSettings {
  const AppSettings({
    this.sheetUrl,
    this.deck = 'graphite',
    this.background = 'glow',
    this.customBackgroundPath,
    this.dim = 30,
    this.refreshOnStart = true,
    this.useCacheOffline = true,
    this.animations = true,
    this.sounds = false,
    this.fullscreenReveal = true,
    this.rememberWindow = true,
    this.seasonalBackground = false,
    this.language = 'ru',
    this.window,
  });

  final String? sheetUrl;
  final String deck;
  final String background;
  final String? customBackgroundPath;

  /// 0–80 in steps of 5.
  final int dim;
  final bool refreshOnStart;
  final bool useCacheOffline;
  final bool animations;
  final bool sounds;
  final bool fullscreenReveal;
  final bool rememberWindow;

  /// When on, the four photo backgrounds follow the calendar.
  final bool seasonalBackground;
  final String language;
  final WindowPlacement? window;

  /// The background actually painted, after the seasonal override.
  String get effectiveBackground =>
      seasonalBackground ? seasonForDate(DateTime.now()) : background;

  static String seasonForDate(DateTime d) => switch (d.month) {
        12 || 1 || 2 => 'winter',
        3 || 4 || 5 => 'spring',
        6 || 7 || 8 => 'summer',
        _ => 'autumn',
      };

  AppSettings copyWith({
    String? sheetUrl,
    bool clearSheetUrl = false,
    String? deck,
    String? background,
    String? customBackgroundPath,
    bool clearCustomBackground = false,
    int? dim,
    bool? refreshOnStart,
    bool? useCacheOffline,
    bool? animations,
    bool? sounds,
    bool? fullscreenReveal,
    bool? rememberWindow,
    bool? seasonalBackground,
    String? language,
    WindowPlacement? window,
  }) =>
      AppSettings(
        sheetUrl: clearSheetUrl ? null : (sheetUrl ?? this.sheetUrl),
        deck: deck ?? this.deck,
        background: background ?? this.background,
        customBackgroundPath: clearCustomBackground
            ? null
            : (customBackgroundPath ?? this.customBackgroundPath),
        dim: dim ?? this.dim,
        refreshOnStart: refreshOnStart ?? this.refreshOnStart,
        useCacheOffline: useCacheOffline ?? this.useCacheOffline,
        animations: animations ?? this.animations,
        sounds: sounds ?? this.sounds,
        fullscreenReveal: fullscreenReveal ?? this.fullscreenReveal,
        rememberWindow: rememberWindow ?? this.rememberWindow,
        seasonalBackground: seasonalBackground ?? this.seasonalBackground,
        language: language ?? this.language,
        window: window ?? this.window,
      );
}

class SettingsRepo {
  SettingsRepo(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsRepo> open() async =>
      SettingsRepo(await SharedPreferences.getInstance());

  static const _kSheetUrl = 'sheetUrl';
  static const _kDeck = 'deck';
  static const _kBackground = 'background';
  static const _kCustomBg = 'customBackgroundPath';
  static const _kDim = 'dim';
  static const _kRefreshOnStart = 'refreshOnStart';
  static const _kUseCacheOffline = 'useCacheOffline';
  static const _kAnimations = 'animations';
  static const _kSounds = 'sounds';
  static const _kFullscreenReveal = 'fullscreenReveal';
  static const _kRememberWindow = 'rememberWindow';
  static const _kSeasonal = 'seasonalBackground';
  static const _kLanguage = 'language';
  static const _kWinW = 'windowWidth';
  static const _kWinH = 'windowHeight';
  static const _kWinX = 'windowX';
  static const _kWinY = 'windowY';
  static const _kWinMax = 'windowMaximized';

  // The store is a plain JSON file on Windows. Read every value by type test
  // rather than by getter, so a stale or hand-edited entry of the wrong type
  // falls back to its default instead of throwing at start-up.
  String? _string(String key) {
    final v = _prefs.get(key);
    return v is String ? v : null;
  }

  bool? _bool(String key) {
    final v = _prefs.get(key);
    return v is bool ? v : null;
  }

  double? _number(String key) {
    final v = _prefs.get(key);
    return v is num ? v.toDouble() : null;
  }

  AppSettings read() {
    try {
      final w = _number(_kWinW);
      final h = _number(_kWinH);
      return AppSettings(
        sheetUrl: _string(_kSheetUrl),
        deck: _string(_kDeck) ?? 'graphite',
        background: _string(_kBackground) ?? 'glow',
        customBackgroundPath: _string(_kCustomBg),
        dim: (_number(_kDim) ?? 30).round().clamp(0, 80),
        refreshOnStart: _bool(_kRefreshOnStart) ?? true,
        useCacheOffline: _bool(_kUseCacheOffline) ?? true,
        animations: _bool(_kAnimations) ?? true,
        sounds: _bool(_kSounds) ?? false,
        fullscreenReveal: _bool(_kFullscreenReveal) ?? true,
        rememberWindow: _bool(_kRememberWindow) ?? true,
        seasonalBackground: _bool(_kSeasonal) ?? false,
        language: _string(_kLanguage) == 'en' ? 'en' : 'ru',
        window: (w == null || h == null)
            ? null
            : WindowPlacement(
                width: w,
                height: h,
                x: _number(_kWinX),
                y: _number(_kWinY),
                maximized: _bool(_kWinMax) ?? false,
              ),
      );
    } catch (_) {
      // An unreadable store must never cost the user a working app.
      return const AppSettings();
    }
  }

  Future<void> write(AppSettings s) async {
    if (s.sheetUrl == null) {
      await _prefs.remove(_kSheetUrl);
    } else {
      await _prefs.setString(_kSheetUrl, s.sheetUrl!);
    }
    await _prefs.setString(_kDeck, s.deck);
    await _prefs.setString(_kBackground, s.background);
    if (s.customBackgroundPath == null) {
      await _prefs.remove(_kCustomBg);
    } else {
      await _prefs.setString(_kCustomBg, s.customBackgroundPath!);
    }
    await _prefs.setInt(_kDim, s.dim);
    await _prefs.setBool(_kRefreshOnStart, s.refreshOnStart);
    await _prefs.setBool(_kUseCacheOffline, s.useCacheOffline);
    await _prefs.setBool(_kAnimations, s.animations);
    await _prefs.setBool(_kSounds, s.sounds);
    await _prefs.setBool(_kFullscreenReveal, s.fullscreenReveal);
    await _prefs.setBool(_kRememberWindow, s.rememberWindow);
    await _prefs.setBool(_kSeasonal, s.seasonalBackground);
    await _prefs.setString(_kLanguage, s.language);
    final w = s.window;
    if (w != null) {
      await _prefs.setDouble(_kWinW, w.width);
      await _prefs.setDouble(_kWinH, w.height);
      if (w.x != null) await _prefs.setDouble(_kWinX, w.x!);
      if (w.y != null) await _prefs.setDouble(_kWinY, w.y!);
      await _prefs.setBool(_kWinMax, w.maximized);
    }
  }

  /// Copies a user-picked image into the app folder so we never depend on the
  /// original path staying put.
  static Future<String> importBackground(String sourcePath) async {
    final dir = await getApplicationSupportDirectory();
    final backgrounds = Directory('${dir.path}${Platform.pathSeparator}backgrounds');
    if (!backgrounds.existsSync()) backgrounds.createSync(recursive: true);
    final ext = sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.'))
        : '.img';
    final target =
        '${backgrounds.path}${Platform.pathSeparator}custom_${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(sourcePath).copy(target);
    return target;
  }
}
