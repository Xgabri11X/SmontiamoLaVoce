import 'dart:math' as math;

import 'fft.dart';

class VowelEstimate {
  const VowelEstimate({
    required this.label,
    required this.f1,
    required this.f2,
    required this.score,
    required this.confidence,
  });

  final String label;
  final double f1;
  final double f2;
  final double score;
  final double confidence;
}

class _VowelPrototype {
  const _VowelPrototype(this.label, this.f1, this.f2);

  final String label;
  final double f1;
  final double f2;
}

class SpectralAnalyzer {
  SpectralAnalyzer(this.sampleRate);
  final int sampleRate;

  static const double reconstructionMaxHz = 20000.0;

  static const _vowels = <_VowelPrototype>[
    _VowelPrototype('I', 300, 2300),
    _VowelPrototype('E', 430, 2050),
    _VowelPrototype('A', 750, 1300),
    _VowelPrototype('O', 450, 900),
    _VowelPrototype('U', 320, 700),
  ];

  int harmonicCountTo(double f0, {double maxHz = reconstructionMaxHz}) {
    if (f0 <= 0) return 0;
    final safeMax = math.min(maxHz, sampleRate / 2 - 120.0);
    return math.max(1, (safeMax / f0).floor());
  }

  List<double> _stableWindow(List<double> samples, int wanted) {
    if (samples.length <= wanted) return List<double>.from(samples);
    final hop = math.max(256, wanted ~/ 5);
    var bestStart = 0;
    var bestRms = -1.0;
    for (var start = 0; start + wanted <= samples.length; start += hop) {
      var sum = 0.0;
      for (var i = start; i < start + wanted; i += 4) {
        sum += samples[i] * samples[i];
      }
      final rms = sum / (wanted / 4);
      if (rms > bestRms) {
        bestRms = rms;
        bestStart = start;
      }
    }
    return samples.sublist(bestStart, bestStart + wanted);
  }

  double? estimatePitch(List<double> samples) {
    if (samples.length < 2048) return null;

    final wanted = math.min(samples.length, (sampleRate * 0.55).round());
    final raw = _stableWindow(samples, wanted);

    final factor = math.max(1, (sampleRate / 12000).floor());
    final rate = sampleRate / factor;
    final x = <double>[];
    for (var i = 0; i < raw.length; i += factor) {
      x.add(raw[i]);
    }
    if (x.length < 512) return null;

    final mean = x.reduce((a, b) => a + b) / x.length;
    for (var i = 0; i < x.length; i++) {
      x[i] -= mean;
    }

    final lagMin = math.max(2, (rate / 500).floor());
    final lagMax = math.min(x.length ~/ 2, (rate / 70).ceil());
    if (lagMax <= lagMin + 2) return null;

    final difference = List<double>.filled(lagMax + 1, 0.0);
    for (var tau = 1; tau <= lagMax; tau++) {
      var sum = 0.0;
      final limit = x.length - tau;
      for (var i = 0; i < limit; i++) {
        final d = x[i] - x[i + tau];
        sum += d * d;
      }
      difference[tau] = sum;
    }

    final cmnd = List<double>.filled(lagMax + 1, 1.0);
    var running = 0.0;
    for (var tau = 1; tau <= lagMax; tau++) {
      running += difference[tau];
      cmnd[tau] = running > 1e-12
          ? difference[tau] * tau / running
          : 1.0;
    }

    const threshold = 0.16;
    var selected = -1;
    for (var tau = lagMin + 1; tau < lagMax; tau++) {
      if (cmnd[tau] < threshold &&
          cmnd[tau] <= cmnd[tau - 1] &&
          cmnd[tau] < cmnd[tau + 1]) {
        selected = tau;
        break;
      }
    }

    if (selected < 0) {
      var best = double.infinity;
      for (var tau = lagMin; tau <= lagMax; tau++) {
        if (cmnd[tau] < best) {
          best = cmnd[tau];
          selected = tau;
        }
      }
    }

    if (selected <= 0 || cmnd[selected] > 0.55) return null;

    var refinedLag = selected.toDouble();
    if (selected > lagMin && selected < lagMax) {
      final ym1 = cmnd[selected - 1];
      final y0 = cmnd[selected];
      final yp1 = cmnd[selected + 1];
      final denom = ym1 - 2 * y0 + yp1;
      if (denom.abs() > 1e-12) {
        final delta = 0.5 * (ym1 - yp1) / denom;
        if (delta.abs() <= 1.0) refinedLag += delta;
      }
    }

    var f = rate / refinedLag;

    if (f / 2 >= 65) {
      final pF = math.sqrt(math.max(0.0, _goertzelPower(raw, f)));
      final pHalf = math.sqrt(math.max(0.0, _goertzelPower(raw, f / 2)));
      final pThreeHalf = f * 1.5 < sampleRate / 2
          ? math.sqrt(math.max(0.0, _goertzelPower(raw, f * 1.5)))
          : 0.0;
      if ((pHalf > pF * 0.10 && pThreeHalf > pF * 0.10) ||
          (pHalf + pThreeHalf > pF * 0.55)) {
        f /= 2.0;
      }
    }

    if (f < 65 || f > 520) return null;
    return f;
  }

  double _goertzelPower(List<double> samples, double frequency) {
    if (frequency <= 0 || frequency >= sampleRate / 2) return 0.0;
    final maxN = math.min(samples.length, (sampleRate * 0.45).round());
    final stable = _stableWindow(samples, maxN);
    return _goertzelPowerOnWindow(_hannWindow(stable), frequency);
  }

  List<double> _hannWindow(List<double> input) {
    if (input.length <= 1) return List<double>.from(input);
    return List<double>.generate(input.length, (j) {
      final win = 0.5 - 0.5 * math.cos(2 * math.pi * j / (input.length - 1));
      return input[j] * win;
    });
  }

  double _goertzelPowerOnWindow(List<double> windowed, double frequency) {
    if (frequency <= 0 || frequency >= sampleRate / 2 || windowed.isEmpty) {
      return 0.0;
    }
    final w = 2 * math.pi * frequency / sampleRate;
    final coeff = 2 * math.cos(w);
    var s0 = 0.0, s1 = 0.0, s2 = 0.0;
    for (final sample in windowed) {
      s0 = sample + coeff * s1 - s2;
      s2 = s1;
      s1 = s0;
    }
    return s1 * s1 + s2 * s2 - coeff * s1 * s2;
  }

  List<double> harmonicAmplitudes(
    List<double> samples,
    double f0, {
    int count = 20,
  }) {
    final values = <double>[];
    final wanted = math.min(samples.length, (sampleRate * 0.45).round());
    final stable = _stableWindow(samples, wanted);
    final windowed = _hannWindow(stable);
    for (var n = 1; n <= count; n++) {
      final f = n * f0;
      if (f >= sampleRate / 2 - 80) {
        values.add(0.0);
      } else {
        // A real sustained voice has vibrato and the pitch estimate is never
        // exact to infinite precision. At high harmonic number even a tiny
        // f0 error moves the spectral peak by many Hz. Integrate a narrow
        // band around n*f0 instead of sampling one infinitely thin frequency.
        final halfWidth = math.min(
          f0 * 0.32,
          math.max(6.0, f * 0.0035 + 4.0),
        );
        var power = 0.0;
        const offsets = <double>[-1.0, -0.5, 0.0, 0.5, 1.0];
        for (final offset in offsets) {
          final probe = f + offset * halfWidth;
          if (probe > 0 && probe < sampleRate / 2 - 50) {
            power += math.max(0.0, _goertzelPowerOnWindow(windowed, probe));
          }
        }
        values.add(math.sqrt(power / offsets.length));
      }
    }
    final maxV = values.fold<double>(0, math.max);
    if (maxV <= 0) return values;
    return values.map((v) => v / maxV).toList();
  }

  VowelEstimate? estimateVowel(List<double> samples, double f0) {
    if (f0 < 65 || f0 > 520) return null;
    final maxHz = math.min(3000.0, sampleRate / 2 - 200.0);
    final count = (maxHz / f0).floor();
    if (count < 6) return null;

    final amps = harmonicAmplitudes(samples, f0, count: count);
    final observed = <double>[];
    final frequencies = <double>[];
    for (var i = 0; i < amps.length; i++) {
      final h = i + 1;
      final f = h * f0;
      if (f < 180 || f > maxHz) continue;
      // Compensate part of the normal glottal spectral tilt so that F2 is not
      // systematically hidden by the stronger low harmonics.
      final corrected = amps[i] * math.pow(h, 1.0);
      observed.add(math.log(corrected + 0.06));
      frequencies.add(f);
    }
    if (observed.length < 5) return null;

    final obsZ = _standardize(observed);
    var bestScore = -double.infinity;
    var secondScore = -double.infinity;
    _VowelPrototype? best;

    for (final vowel in _vowels) {
      final template = <double>[];
      for (final f in frequencies) {
        final envelope = 0.08 +
            1.65 * _resonance(f, vowel.f1, 150) +
            1.10 * _resonance(f, vowel.f2, 260) +
            0.42 * _resonance(f, 2700, 420);
        template.add(math.log(envelope + 0.06));
      }
      final tplZ = _standardize(template);
      var score = 0.0;
      for (var i = 0; i < obsZ.length; i++) {
        score += obsZ[i] * tplZ[i];
      }
      score /= obsZ.length;
      if (score > bestScore) {
        secondScore = bestScore;
        bestScore = score;
        best = vowel;
      } else if (score > secondScore) {
        secondScore = score;
      }
    }

    if (best == null) return null;
    final margin = secondScore.isFinite ? bestScore - secondScore : 0.0;
    final confidence = ((margin + 0.04) / 0.24).clamp(0.0, 1.0).toDouble();
    return VowelEstimate(
      label: best.label,
      f1: best.f1,
      f2: best.f2,
      score: bestScore,
      confidence: confidence,
    );
  }

  List<double> _standardize(List<double> x) {
    final mean = x.reduce((a, b) => a + b) / x.length;
    var variance = 0.0;
    for (final v in x) {
      final d = v - mean;
      variance += d * d;
    }
    final sd = math.sqrt(variance / x.length + 1e-12);
    return x.map((v) => (v - mean) / sd).toList();
  }

  double _resonance(double f, double center, double bandwidth) {
    final x = (f - center) / (bandwidth * 0.5);
    return 1 / (1 + x * x);
  }

  (List<double>, List<double>) spectrum(
    List<double> samples, {
    double maxHz = 5000,
    int bins = 160,
  }) {
    final n = math.min(4096, samples.length);
    final source = _stableWindow(samples, n);
    final mean = source.reduce((a, b) => a + b) / source.length;
    final windowed = List<double>.generate(source.length, (i) {
      final h = 0.5 - 0.5 * math.cos(2 * math.pi * i / (source.length - 1));
      return (source[i] - mean) * h;
    });
    final fft = fftReal(windowed);
    final maxIndex = math.min(
      fft.length ~/ 2 - 1,
      (maxHz * fft.length / sampleRate).floor(),
    );
    final hz = <double>[];
    final mag = <double>[];
    var global = 1e-12;
    for (var b = 0; b < bins; b++) {
      final lo = (b * maxIndex / bins).floor();
      final hi = math.max(lo + 1, ((b + 1) * maxIndex / bins).ceil());
      var m = 0.0;
      for (var i = lo; i < hi && i < fft.length ~/ 2; i++) {
        m = math.max(m, fft[i].magnitude);
      }
      global = math.max(global, m);
      hz.add((lo + hi) * 0.5 * sampleRate / fft.length);
      mag.add(m);
    }
    for (var i = 0; i < mag.length; i++) {
      mag[i] = math.sqrt(mag[i] / global);
    }
    return (hz, mag);
  }
}
