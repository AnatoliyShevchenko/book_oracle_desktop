import 'package:book_oracle/data/settings_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SettingsRepo> repoWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SettingsRepo(await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an empty store yields the documented defaults', () async {
    final s = (await repoWith(<String, Object>{})).read();
    expect(s.sheetUrl, isNull);
    expect(s.deck, 'graphite');
    expect(s.background, 'glow');
    expect(s.dim, 30);
    expect(s.refreshOnStart, isTrue);
    expect(s.useCacheOffline, isTrue);
    expect(s.animations, isTrue);
    expect(s.sounds, isFalse);
    expect(s.fullscreenReveal, isTrue);
    expect(s.rememberWindow, isTrue);
    expect(s.seasonalBackground, isFalse);
    expect(s.language, 'ru');
    expect(s.window, isNull);
  });

  test('stored values are read back', () async {
    final s = (await repoWith(<String, Object>{
      'sheetUrl': 'https://docs.google.com/spreadsheets/d/x/edit',
      'deck': 'coven',
      'background': 'winter',
      'dim': 55,
      'sounds': true,
      'language': 'en',
      'windowWidth': 1600.0,
      'windowHeight': 900.0,
      'windowX': 120.0,
      'windowY': 60.0,
      'windowMaximized': true,
    }))
        .read();
    expect(s.deck, 'coven');
    expect(s.background, 'winter');
    expect(s.dim, 55);
    expect(s.sounds, isTrue);
    expect(s.language, 'en');
    expect(s.window!.width, 1600);
    expect(s.window!.height, 900);
    expect(s.window!.x, 120);
    expect(s.window!.maximized, isTrue);
  });

  test('window geometry stored as ints still reads', () async {
    // A hand-edited or externally written store can hold 1536 rather than
    // 1536.0; that must not take the app down.
    final s = (await repoWith(<String, Object>{
      'windowWidth': 1536,
      'windowHeight': 864,
    }))
        .read();
    expect(s.window, isNotNull);
    expect(s.window!.width, 1536.0);
    expect(s.window!.height, 864.0);
  });

  test('values of the wrong type fall back to their defaults', () async {
    final s = (await repoWith(<String, Object>{
      'deck': 42,
      'dim': 'lots',
      'animations': 'yes',
      'windowWidth': 'wide',
      'language': 'klingon',
    }))
        .read();
    expect(s.deck, 'graphite');
    expect(s.dim, 30);
    expect(s.animations, isTrue);
    expect(s.window, isNull);
    expect(s.language, 'ru');
  });

  test('dim is clamped into 0–80', () async {
    expect((await repoWith(<String, Object>{'dim': 999})).read().dim, 80);
    expect((await repoWith(<String, Object>{'dim': -20})).read().dim, 0);
  });

  test('a half-written window entry is ignored', () async {
    final s = (await repoWith(<String, Object>{'windowWidth': 1600.0})).read();
    expect(s.window, isNull);
  });

  test('settings survive a write/read round trip', () async {
    final repo = await repoWith(<String, Object>{});
    const next = AppSettings(
      sheetUrl: 'https://docs.google.com/spreadsheets/d/y/edit',
      deck: 'garden',
      background: 'summer',
      dim: 45,
      sounds: true,
      seasonalBackground: true,
      language: 'en',
      window: WindowPlacement(width: 1440, height: 810, x: 10, y: 20),
    );
    await repo.write(next);

    final back = repo.read();
    expect(back.sheetUrl, next.sheetUrl);
    expect(back.deck, 'garden');
    expect(back.background, 'summer');
    expect(back.dim, 45);
    expect(back.sounds, isTrue);
    expect(back.seasonalBackground, isTrue);
    expect(back.language, 'en');
    expect(back.window!.width, 1440);
    expect(back.window!.y, 20);
  });

  test('clearing the sheet URL removes it', () async {
    final repo = await repoWith(<String, Object>{'sheetUrl': 'x'});
    await repo.write(const AppSettings());
    expect(repo.read().sheetUrl, isNull);
  });
}
