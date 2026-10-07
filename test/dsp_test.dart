import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:smontiamo_la_voce/dsp/spectral_analyzer.dart';

void main() {
  test('riconosce circa 220 Hz anche con seconda armonica forte', () {
    const sr = 44100;
    const f0 = 220.0;
    final samples = List<double>.generate(sr, (i) {
      final t = i / sr;
      return 0.22 * math.sin(2 * math.pi * f0 * t) +
          0.85 * math.sin(2 * math.pi * 2 * f0 * t + 0.3) +
          0.40 * math.sin(2 * math.pi * 3 * f0 * t - 0.2);
    });
    final found = SpectralAnalyzer(sr).estimatePitch(samples);
    expect(found, isNotNull);
    expect((found! - f0).abs(), lessThan(4.0));
  });

  test('estrae armoniche normalizzate', () {
    const sr = 44100;
    const f0 = 200.0;
    final samples = List<double>.generate(sr, (i) {
      final t = i / sr;
      return math.sin(2 * math.pi * f0 * t) +
          0.5 * math.sin(2 * math.pi * 2 * f0 * t) +
          0.25 * math.sin(2 * math.pi * 3 * f0 * t);
    });
    final h = SpectralAnalyzer(sr).harmonicAmplitudes(samples, f0, count: 5);
    expect(h[0], closeTo(1.0, 0.08));
    expect(h[1], closeTo(0.5, 0.10));
    expect(h[2], closeTo(0.25, 0.10));
  });

  test('calcola abbastanza armoniche per arrivare a circa 20 kHz', () {
    final analyzer = SpectralAnalyzer(44100);
    expect(analyzer.harmonicCountTo(200), 100);
    expect(analyzer.harmonicCountTo(100), 200);
  });

  test('riconosce vocali sintetiche A e I', () {
    const sr = 44100;
    const f0 = 180.0;
    final analyzer = SpectralAnalyzer(sr);

    final a = _syntheticVowel(sr, f0, 750, 1300);
    final i = _syntheticVowel(sr, f0, 300, 2300);

    expect(analyzer.estimateVowel(a, f0)?.label, 'A');
    expect(analyzer.estimateVowel(i, f0)?.label, 'I');
  });
}

List<double> _syntheticVowel(
  int sampleRate,
  double f0,
  double f1,
  double f2,
) {
  const seconds = 0.8;
  final count = (sampleRate * seconds).round();
  final maxH = (3000 / f0).floor();
  return List<double>.generate(count, (index) {
    final t = index / sampleRate;
    var value = 0.0;
    for (var h = 1; h <= maxH; h++) {
      final f = h * f0;
      final tilt = 1 / math.pow(h, 1.18);
      final envelope = 0.08 +
          1.65 * _resonance(f, f1, 150) +
          1.10 * _resonance(f, f2, 260) +
          0.42 * _resonance(f, 2700, 420);
      value += tilt * envelope * math.sin(2 * math.pi * f * t + h * 0.13);
    }
    return value;
  });
}

double _resonance(double f, double center, double bandwidth) {
  final x = (f - center) / (bandwidth * 0.5);
  return 1 / (1 + x * x);
}
