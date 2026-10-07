import 'dart:math' as math;
import 'dart:typed_data';

class AudioSynth {
  static Uint8List harmonicWav({
    required double f0,
    required List<double> amplitudes,
    required List<bool> enabled,
    int sampleRate = 44100,
    double seconds = 2.2,
  }) {
    final nSamples = (sampleRate * seconds).round();
    final out = List<double>.filled(nSamples, 0.0);
    final random = math.Random(42);
    final phase = List<double>.generate(amplitudes.length, (_) => random.nextDouble() * 2 * math.pi);
    for (var i = 0; i < nSamples; i++) {
      final t = i / sampleRate;
      final env = _softEnvelope(t, seconds);
      final vibrato = 1.0 + 0.0015 * math.sin(2 * math.pi * 5.2 * t);
      var y = 0.0;
      for (var h = 0; h < amplitudes.length && h < enabled.length; h++) {
        if (!enabled[h]) continue;
        final n = h + 1;
        y += amplitudes[h] * math.sin(2 * math.pi * n * f0 * vibrato * t + phase[h]);
      }
      out[i] = y * env;
    }
    return wavFromSamples(_normalize(out), sampleRate);
  }

  static Uint8List lpcNaturalVowelWav({
    required List<double> source,
    required int sourceSampleRate,
    required double f1,
    required double f2,
    double f3 = 2700,
    int order = 20,
    double maxSeconds = 2.0,
  }) {
    if (source.length < order * 8) {
      return vowelWav(f0: 180, f1: f1, f2: f2, sampleRate: sourceSampleRate);
    }

    final wanted = math.min(source.length, (sourceSampleRate * maxSeconds).round());
    final start = math.max(0, (source.length - wanted) ~/ 2);
    final x = List<double>.from(source.sublist(start, start + wanted));
    final mean = x.reduce((a, b) => a + b) / x.length;
    for (var i = 0; i < x.length; i++) x[i] -= mean;

    // Pre-emphasis: makes LPC estimate the vocal-tract envelope rather than
    // spending most coefficients on the natural high-frequency roll-off.
    final pre = List<double>.filled(x.length, 0.0);
    pre[0] = x[0];
    for (var i = 1; i < x.length; i++) {
      pre[i] = x[i] - 0.96 * x[i - 1];
    }

    final r = List<double>.filled(order + 1, 0.0);
    for (var lag = 0; lag <= order; lag++) {
      var sum = 0.0;
      for (var n = lag; n < pre.length; n++) {
        sum += pre[n] * pre[n - lag];
      }
      r[lag] = sum;
    }
    if (r[0].abs() < 1e-12) {
      return vowelWav(f0: 180, f1: f1, f2: f2, sampleRate: sourceSampleRate);
    }

    // Levinson-Durbin recursion. Coefficients follow
    // x[n] + a1*x[n-1] + ... = residual[n].
    var a = List<double>.filled(order + 1, 0.0);
    a[0] = 1.0;
    var error = r[0];
    for (var i = 1; i <= order; i++) {
      var acc = r[i];
      for (var j = 1; j < i; j++) acc += a[j] * r[i - j];
      var reflection = -acc / (error + 1e-12);
      reflection = reflection.clamp(-0.985, 0.985).toDouble();
      final next = List<double>.from(a);
      for (var j = 1; j < i; j++) {
        next[j] = a[j] + reflection * a[i - j];
      }
      next[i] = reflection;
      a = next;
      error *= (1 - reflection * reflection);
      if (error < r[0] * 1e-9) break;
    }

    final residual = List<double>.filled(pre.length, 0.0);
    for (var n = 0; n < pre.length; n++) {
      var e = pre[n];
      for (var k = 1; k <= order && k <= n; k++) {
        e += a[k] * pre[n - k];
      }
      residual[n] = e;
    }

    var y = _resonator(residual, sourceSampleRate, f1, 150);
    y = _resonator(y, sourceSampleRate, f2, 260);
    y = _resonator(y, sourceSampleRate, f3, 430);

    // De-emphasis restores a natural glottal tilt. A gentle one-pole smoothing
    // also suppresses whistle-like isolated high-frequency components.
    final de = List<double>.filled(y.length, 0.0);
    var previous = 0.0;
    var smooth = 0.0;
    for (var i = 0; i < y.length; i++) {
      final restored = y[i] + 0.94 * previous;
      previous = restored;
      smooth = 0.82 * smooth + 0.18 * restored;
      de[i] = smooth * _softEnvelope(i / sourceSampleRate, y.length / sourceSampleRate);
    }
    return wavFromSamples(_normalize(de), sourceSampleRate);
  }

  static List<double> _resonator(
    List<double> input,
    int sampleRate,
    double frequency,
    double bandwidth,
  ) {
    final theta = 2 * math.pi * frequency / sampleRate;
    final radius = math.exp(-math.pi * bandwidth / sampleRate);
    final c1 = 2 * radius * math.cos(theta);
    final c2 = -radius * radius;
    final out = List<double>.filled(input.length, 0.0);
    var y1 = 0.0;
    var y2 = 0.0;
    for (var i = 0; i < input.length; i++) {
      final y = input[i] + c1 * y1 + c2 * y2;
      out[i] = y;
      y2 = y1;
      y1 = y;
    }
    return out;
  }

  static Uint8List vowelWav({
    required double f0,
    required double f1,
    required double f2,
    double f3 = 2700,
    int sampleRate = 44100,
    double seconds = 1.8,
  }) {
    final harmonics = math.min(60, (sampleRate * 0.46 / f0).floor());
    final amps = List<double>.filled(harmonics, 0.0);
    for (var h = 1; h <= harmonics; h++) {
      final f = h * f0;
      final sourceTilt = 1 / math.pow(h, 1.18);
      final r1 = _resonance(f, f1, 150);
      final r2 = _resonance(f, f2, 260);
      final r3 = _resonance(f, f3, 420);
      final highCut = 1 / (1 + math.pow(math.max(0.0, (f - 2400) / 1700), 2));
      amps[h - 1] = sourceTilt * (0.08 + 1.65 * r1 + 1.10 * r2 + 0.42 * r3) * highCut;
    }
    final peak = amps.fold<double>(1e-9, math.max);
    for (var i = 0; i < amps.length; i++) amps[i] /= peak;

    final random = math.Random(1234);
    final phases = List<double>.generate(harmonics, (_) => random.nextDouble() * 2 * math.pi);
    final nSamples = (sampleRate * seconds).round();
    final out = List<double>.filled(nSamples, 0.0);
    var breath = 0.0;
    for (var i = 0; i < nSamples; i++) {
      final t = i / sampleRate;
      final env = _softEnvelope(t, seconds);
      final vibrato = 1.0 + 0.0022 * math.sin(2 * math.pi * 5.1 * t);
      var y = 0.0;
      for (var h = 1; h <= harmonics; h++) {
        y += amps[h - 1] * math.sin(2 * math.pi * h * f0 * vibrato * t + phases[h - 1]);
      }
      // A tiny low-passed aspiration component helps avoid the perfectly periodic,
      // metallic quality of a pure additive oscillator bank.
      final white = random.nextDouble() * 2 - 1;
      breath = 0.93 * breath + 0.07 * white;
      out[i] = env * (y + 0.018 * breath);
    }
    return wavFromSamples(_normalize(out), sampleRate);
  }

  static double _resonance(double f, double center, double bandwidth) {
    final x = (f - center) / (bandwidth * 0.5);
    return 1 / (1 + x * x);
  }

  static double _softEnvelope(double t, double duration) {
    const edge = 0.07;
    final attack = math.min(1.0, t / edge);
    final release = math.min(1.0, (duration - t) / edge);
    return math.max(0.0, math.min(attack, release));
  }

  static List<double> _normalize(List<double> x) {
    final peak = x.fold<double>(1e-9, (m, v) => math.max(m, v.abs()));
    final gain = 0.86 / peak;
    return x.map((v) => v * gain).toList();
  }

  static Uint8List wavFromSamples(List<double> samples, int sampleRate) {
    final dataSize = samples.length * 2;
    final bytes = ByteData(44 + dataSize);
    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) bytes.setUint8(offset + i, s.codeUnitAt(i));
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataSize, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, dataSize, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
      bytes.setInt16(44 + i * 2, v, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }
}
