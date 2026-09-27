// Synthesises the card sounds into assets/sounds/.
//
//   fvm dart run tool/generate_sounds.dart
//
// Everything here is generated from noise and sine partials, so the app ships
// no third-party audio and the sounds stay in the app's quiet register.
// The RNG is seeded, so re-running produces byte-identical files.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int kSampleRate = 44100;

void main() {
  final dir = Directory('assets/sounds');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  final sounds = <String, List<double>>{
    'flip': flip(seed: 1),
    'deal': deal(seed: 2),
    'shuffle': shuffle(seed: 3),
    'reveal': reveal(),
  };

  sounds.forEach((name, samples) {
    final file = File('${dir.path}/$name.wav');
    file.writeAsBytesSync(encodeWav(samples));
    final ms = (samples.length / kSampleRate * 1000).round();
    stdout.writeln(
        '${file.path.padRight(28)} ${ms.toString().padLeft(5)} ms  '
        '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB');
  });
}

// ---------------------------------------------------------------------------
// The sounds
// ---------------------------------------------------------------------------

/// A card turned over: a short filtered-noise flick with a soft low thump.
List<double> flip({required int seed}) {
  const seconds = 0.16;
  final n = (kSampleRate * seconds).round();
  final rng = math.Random(seed);
  final out = List<double>.filled(n, 0);

  // Noise through a band-pass that sweeps upward, like paper letting go.
  final band = _Biquad();
  for (var i = 0; i < n; i++) {
    final t = i / kSampleRate;
    final centre = 1200 + 1800 * (t / seconds);
    band.bandPass(centre, 2.0);
    final env = _attackDecay(t, attack: 0.002, tau: 0.028);
    out[i] = band.process(rng.nextDouble() * 2 - 1) * env;
  }

  // A touch of body so it does not read as pure hiss.
  for (var i = 0; i < n; i++) {
    final t = i / kSampleRate;
    out[i] += math.sin(2 * math.pi * 140 * t) *
        _attackDecay(t, attack: 0.001, tau: 0.030) *
        0.12;
  }

  return _normalise(out, 0.70);
}

/// Cards flying onto the table: lower and softer than a flip.
List<double> deal({required int seed}) {
  const seconds = 0.20;
  final n = (kSampleRate * seconds).round();
  final rng = math.Random(seed);
  final out = List<double>.filled(n, 0);
  final band = _Biquad();

  for (var i = 0; i < n; i++) {
    final t = i / kSampleRate;
    final centre = 1600 - 900 * (t / seconds);
    band.bandPass(centre, 1.2);
    final env = _attackDecay(t, attack: 0.010, tau: 0.050);
    out[i] = band.process(rng.nextDouble() * 2 - 1) * env;
  }

  for (var i = 0; i < n; i++) {
    final t = i / kSampleRate;
    out[i] += math.sin(2 * math.pi * 110 * t) *
        _attackDecay(t, attack: 0.004, tau: 0.045) *
        0.10;
  }

  return _normalise(out, 0.58);
}

/// Gathering the deck: a handful of overlapping flicks plus a low rustle.
List<double> shuffle({required int seed}) {
  const seconds = 0.55;
  final n = (kSampleRate * seconds).round();
  final rng = math.Random(seed);
  final out = List<double>.filled(n, 0);

  // A broad rustle underneath.
  final rustle = _Biquad()..lowPass(1400, 0.7);
  for (var i = 0; i < n; i++) {
    final t = i / kSampleRate;
    final env = _attackDecay(t, attack: 0.040, tau: 0.220);
    out[i] = rustle.process(rng.nextDouble() * 2 - 1) * env * 0.5;
  }

  // Individual cards on top.
  for (var k = 0; k < 8; k++) {
    final offset = (rng.nextDouble() * 0.40 * kSampleRate).round();
    final burst = flip(seed: seed * 100 + k);
    final gain = 0.30 + rng.nextDouble() * 0.25;
    for (var i = 0; i < burst.length; i++) {
      final at = offset + i;
      if (at >= n) break;
      out[at] += burst[i] * gain;
    }
  }

  return _normalise(out, 0.62);
}

/// The oracle's answer: a soft G-minor bell with a brief shimmer.
List<double> reveal() {
  const seconds = 1.8;
  final n = (kSampleRate * seconds).round();
  final out = List<double>.filled(n, 0);

  // G3 · Bb3 · D4 — quiet and a little solemn.
  const partials = <(double, double, double)>[
    (196.00, 0.95, 0.55), // (hertz, decay seconds, gain)
    (233.08, 0.80, 0.38),
    (293.66, 0.65, 0.30),
    (392.00, 0.50, 0.16),
  ];

  for (final (hz, tau, gain) in partials) {
    for (var i = 0; i < n; i++) {
      final t = i / kSampleRate;
      final env = _attackDecay(t, attack: 0.012, tau: tau);
      // A second voice a fraction sharp gives a slow, natural beating.
      out[i] += (math.sin(2 * math.pi * hz * t) +
              math.sin(2 * math.pi * (hz + 0.4) * t)) *
          0.5 *
          env *
          gain;
    }
  }

  // A whisper of air at the strike.
  final rng = math.Random(7);
  final air = _Biquad();
  for (var i = 0; i < n; i++) {
    final t = i / kSampleRate;
    air.bandPass(5200, 1.4);
    final env = _attackDecay(t, attack: 0.004, tau: 0.090);
    out[i] += air.process(rng.nextDouble() * 2 - 1) * env * 0.10;
  }

  return _normalise(out, 0.72);
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

/// Linear attack into an exponential tail.
double _attackDecay(double t, {required double attack, required double tau}) {
  if (t < 0) return 0;
  final rise = t < attack ? t / attack : 1.0;
  return rise * math.exp(-(t - (t < attack ? t : attack)) / tau);
}

/// Scales the buffer so its loudest sample sits at [peak], and fades the last
/// few milliseconds so the file cannot click on playback.
List<double> _normalise(List<double> samples, double peak) {
  var max = 0.0;
  for (final s in samples) {
    final a = s.abs();
    if (a > max) max = a;
  }
  if (max == 0) return samples;
  final gain = peak / max;

  final fade = math.min(samples.length, (kSampleRate * 0.006).round());
  for (var i = 0; i < samples.length; i++) {
    var v = samples[i] * gain;
    final fromEnd = samples.length - i;
    if (fromEnd < fade) v *= fromEnd / fade;
    samples[i] = v;
  }
  return samples;
}

/// A direct-form-1 biquad; coefficients may be recomputed every sample, which
/// is what lets the flick sweep its band.
class _Biquad {
  double _b0 = 1, _b1 = 0, _b2 = 0, _a1 = 0, _a2 = 0;
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  void bandPass(double centreHz, double q) {
    final w0 = 2 * math.pi * centreHz / kSampleRate;
    final alpha = math.sin(w0) / (2 * q);
    final a0 = 1 + alpha;
    _b0 = alpha / a0;
    _b1 = 0;
    _b2 = -alpha / a0;
    _a1 = -2 * math.cos(w0) / a0;
    _a2 = (1 - alpha) / a0;
  }

  void lowPass(double cutoffHz, double q) {
    final w0 = 2 * math.pi * cutoffHz / kSampleRate;
    final alpha = math.sin(w0) / (2 * q);
    final cos0 = math.cos(w0);
    final a0 = 1 + alpha;
    _b0 = (1 - cos0) / 2 / a0;
    _b1 = (1 - cos0) / a0;
    _b2 = (1 - cos0) / 2 / a0;
    _a1 = -2 * cos0 / a0;
    _a2 = (1 - alpha) / a0;
  }

  double process(double x) {
    final y = _b0 * x + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }
}

// ---------------------------------------------------------------------------
// WAV container
// ---------------------------------------------------------------------------

/// 16-bit mono PCM.
Uint8List encodeWav(List<double> samples, {int sampleRate = kSampleRate}) {
  const channels = 1;
  const bitsPerSample = 16;
  final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final dataSize = samples.length * blockAlign;

  final bytes = BytesBuilder();
  void ascii(String s) => bytes.add(s.codeUnits);
  void u32(int v) =>
      bytes.add(Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little));
  void u16(int v) =>
      bytes.add(Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little));

  ascii('RIFF');
  u32(36 + dataSize);
  ascii('WAVE');
  ascii('fmt ');
  u32(16); // PCM chunk size
  u16(1); // PCM
  u16(channels);
  u32(sampleRate);
  u32(byteRate);
  u16(blockAlign);
  u16(bitsPerSample);
  ascii('data');
  u32(dataSize);

  final pcm = Uint8List(dataSize);
  final view = pcm.buffer.asByteData();
  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    view.setInt16(i * 2, (clamped * 32767).round(), Endian.little);
  }
  bytes.add(pcm);
  return bytes.takeBytes();
}
