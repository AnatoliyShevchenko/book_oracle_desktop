import 'dart:io';
import 'dart:typed_data';

import 'package:book_oracle/core/sound.dart';
import 'package:book_oracle/data/settings_repo.dart';
import 'package:book_oracle/state/app_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tool/generate_sounds.dart' as gen;

({int channels, int sampleRate, int bits, int samples}) readWavHeader(
    Uint8List b) {
  final view = ByteData.sublistView(b);
  expect(String.fromCharCodes(b.sublist(0, 4)), 'RIFF');
  expect(String.fromCharCodes(b.sublist(8, 12)), 'WAVE');
  expect(String.fromCharCodes(b.sublist(12, 16)), 'fmt ');
  expect(view.getUint16(20, Endian.little), 1, reason: 'PCM');
  expect(String.fromCharCodes(b.sublist(36, 40)), 'data');
  final dataSize = view.getUint32(40, Endian.little);
  expect(b.length, 44 + dataSize, reason: 'declared size matches the file');
  return (
    channels: view.getUint16(22, Endian.little),
    sampleRate: view.getUint32(24, Endian.little),
    bits: view.getUint16(34, Endian.little),
    samples: dataSize ~/ 2,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WAV encoding', () {
    test('writes a well-formed 16-bit mono header', () {
      final wav = gen.encodeWav(<double>[0, 0.5, -0.5, 1, -1]);
      final h = readWavHeader(wav);
      expect(h.channels, 1);
      expect(h.sampleRate, 44100);
      expect(h.bits, 16);
      expect(h.samples, 5);
    });

    test('samples are clamped rather than wrapped around', () {
      final wav = gen.encodeWav(<double>[4.0, -4.0]);
      final view = ByteData.sublistView(wav);
      expect(view.getInt16(44, Endian.little), 32767);
      expect(view.getInt16(46, Endian.little), -32767);
    });
  });

  group('synthesis', () {
    final sounds = <String, List<double>>{
      'flip': gen.flip(seed: 1),
      'deal': gen.deal(seed: 2),
      'shuffle': gen.shuffle(seed: 3),
      'reveal': gen.reveal(),
    };

    sounds.forEach((name, samples) {
      test('$name is audible, unclipped and ends silently', () {
        expect(samples, isNotEmpty);

        var peak = 0.0;
        var energy = 0.0;
        for (final s in samples) {
          final a = s.abs();
          if (a > peak) peak = a;
          energy += s * s;
        }
        final rms = energy <= 0 ? 0.0 : (energy / samples.length);

        expect(peak, greaterThan(0.3), reason: '$name is too quiet');
        expect(peak, lessThanOrEqualTo(0.95), reason: '$name would clip');
        expect(rms, greaterThan(0.0), reason: '$name is silent');

        // The tail is faded, so playback cannot click.
        expect(samples.last.abs(), lessThan(0.02));
      });
    });

    test('the same seed gives byte-identical output', () {
      expect(gen.encodeWav(gen.flip(seed: 1)),
          gen.encodeWav(gen.flip(seed: 1)));
      expect(gen.encodeWav(gen.shuffle(seed: 3)),
          gen.encodeWav(gen.shuffle(seed: 3)));
    });

    test('a different seed gives different output', () {
      expect(gen.encodeWav(gen.flip(seed: 1)),
          isNot(gen.encodeWav(gen.flip(seed: 9))));
    });
  });

  group('the shipped assets', () {
    for (final sfx in Sfx.values) {
      test('${sfx.name} exists and is a readable WAV', () {
        final file = File('assets/${sfx.asset}');
        expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
        final h = readWavHeader(file.readAsBytesSync());
        expect(h.channels, 1);
        expect(h.sampleRate, 44100);
        expect(h.bits, 16);
        expect(h.samples, greaterThan(1000));
      });
    }

    test('pubspec bundles the sounds folder', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('assets/sounds/'));
    });
  });

  group('the sounds switch gates playback', () {
    /// `playSfx` takes a [Ref], so reach it through a throwaway provider.
    final trigger = Provider<void>((ref) => playSfx(ref, Sfx.flip));

    Future<ProviderContainer> container({required bool sounds}) async {
      SharedPreferences.setMockInitialValues(<String, Object>{'sounds': sounds});
      final repo = SettingsRepo(await SharedPreferences.getInstance());
      return ProviderContainer(
        overrides: [settingsRepoProvider.overrideWithValue(repo)],
      );
    }

    test('switched off, the board is never touched', () async {
      final c = await container(sounds: false);
      addTearDown(c.dispose);
      expect(c.read(settingsProvider).sounds, isFalse);

      c.read(trigger);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Untouched: no attempt was made, so nothing could have failed.
      expect(c.read(soundBoardProvider).available, isTrue);
      expect(c.read(soundBoardProvider).lastError, isNull);
    });

    test('the build-wide flag wins over the preference', () async {
      final c = await container(sounds: true);
      addTearDown(c.dispose);
      expect(c.read(settingsProvider).sounds, isTrue);

      c.read(trigger);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Card sounds are off for this build, so even an enabled preference
      // must not reach the board.
      expect(kCardSoundsEnabled, isFalse,
          reason: 'update this test when card sounds are switched back on');
      expect(c.read(soundBoardProvider).available, isTrue);
      expect(c.read(soundBoardProvider).lastError, isNull);
    });
  });

  group('SoundBoard survives a machine with no audio', () {
    test('the first failure switches it off for good', () async {
      final board = SoundBoard();
      addTearDown(board.dispose);
      expect(board.available, isTrue);

      // There is no audio plugin under `flutter test`.
      await board.play(Sfx.flip);

      expect(board.available, isFalse);
      expect(board.lastError, isNotNull);
    });

    test('later calls do not retry', () async {
      final board = SoundBoard();
      addTearDown(board.dispose);

      await board.play(Sfx.flip);
      final first = board.lastError;
      await board.play(Sfx.deal);
      await board.play(Sfx.reveal);

      expect(board.lastError, same(first));
    });

    test('playing after dispose is a no-op', () async {
      final board = SoundBoard()..dispose();
      await board.play(Sfx.flip);
      expect(board.lastError, isNull);
    });
  });
}
