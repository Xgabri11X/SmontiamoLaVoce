import 'dart:math' as math;

import 'fft.dart';

class FricativeAnalysis {
  const FricativeAnalysis({
    required this.voicing,
    required this.periodicity,
    required this.centroidHz,
    required this.highFrequencyRatio,
    required this.closestProfile,
    required this.profileFamily,
    required this.spectrumHz,
    required this.spectrumMagnitude,
  });

  /// 0 = mostly aperiodic/noisy, 1 = clear periodic vocal-fold component.
  final double voicing;
  final double periodicity;
  final double centroidHz;
  final double highFrequencyRatio;
  final String closestProfile;
  final String profileFamily;
  final List<double> spectrumHz;
  final List<double> spectrumMagnitude;
}

class StopAnalysis {
  const StopAnalysis({
    required this.burstTimeMs,
    required this.burstCentroidHz,
    required this.closureDurationMs,
    required this.burstStrength,
    required this.envelope,
    required this.frameHopMs,
    required this.burstSampleIndex,
    required this.closureStartSample,
    required this.closureEndSample,
  });

  final double burstTimeMs;
  final double burstCentroidHz;
  final double closureDurationMs;
  final double burstStrength;
  final List<double> envelope;
  final double frameHopMs;
  final int burstSampleIndex;
  final int closureStartSample;
  final int closureEndSample;
}

class ConsonantAnalyzer {
  ConsonantAnalyzer(this.sampleRate);

  final int sampleRate;

  FricativeAnalysis? analyzeFricative(List<double> samples) {
    if (samples.length < sampleRate * 0.35) return null;

    final window = _centerWindow(samples, math.min(samples.length, 16384));
    if (_rms(window) < 1e-5) return null;

    final periodicity = _periodicity(window);
    final metrics = _spectrumMetrics(window, maxHz: 10000);

    // The periodicity carries most of the voicing information. The low-band
    // energy term makes /z/ and /v/ more robust on phone microphones that
    // slightly attenuate the fundamental.
    final lowCue = ((metrics.lowBandRatio - 0.012) / 0.20)
        .clamp(0.0, 1.0)
        .toDouble();
    final periodicCue = ((periodicity - 0.08) / 0.55)
        .clamp(0.0, 1.0)
        .toDouble();
    final voicing = (0.78 * periodicCue + 0.22 * lowCue)
        .clamp(0.0, 1.0)
        .toDouble();

    final voiced = voicing >= 0.40;
    late final String profile;
    late final String family;

    // Deliberately broad regions: this is a didactic profile, not a clinical
    // phoneme recognizer. /s/ tends to concentrate energy higher than /sh/;
    // labiodental frication is usually broader and less sharply high-pitched.
    if (metrics.centroidHz >= 5600 || metrics.highFrequencyRatio >= 0.66) {
      profile = voiced ? '/z/' : '/s/';
      family = 'alveolare · energia molto alta';
    } else if (metrics.centroidHz <= 3400 && metrics.highFrequencyRatio < 0.48) {
      profile = voiced ? '/ʒ/' : '/ʃ/ (SC)';
      family = 'postalveolare · energia più bassa';
    } else {
      profile = voiced ? '/v/' : '/f/';
      family = 'labiodentale · rumore più diffuso';
    }

    final display = _displaySpectrum(window, maxHz: 10000, bins: 180);

    return FricativeAnalysis(
      voicing: voicing,
      periodicity: periodicity,
      centroidHz: metrics.centroidHz,
      highFrequencyRatio: metrics.highFrequencyRatio,
      closestProfile: profile,
      profileFamily: family,
      spectrumHz: display.$1,
      spectrumMagnitude: display.$2,
    );
  }

  StopAnalysis? analyzeStop(List<double> samples) {
    if (samples.length < sampleRate * 0.55) return null;

    final frame = math.max(64, (sampleRate * 0.010).round());
    final hop = math.max(32, (sampleRate * 0.005).round());
    if (samples.length < frame * 4) return null;

    final envelope = <double>[];
    final frameStarts = <int>[];
    for (var start = 0; start + frame <= samples.length; start += hop) {
      var sum = 0.0;
      for (var i = start; i < start + frame; i++) {
        sum += samples[i] * samples[i];
      }
      envelope.add(math.sqrt(sum / frame));
      frameStarts.add(start);
    }
    if (envelope.length < 20) return null;

    // Gentle smoothing makes the vowel-closure-vowel structure easier to
    // detect while preserving the burst transition.
    final smooth = List<double>.filled(envelope.length, 0.0);
    for (var i = 0; i < envelope.length; i++) {
      var sum = 0.0;
      var count = 0;
      for (var j = math.max(0, i - 1); j <= math.min(envelope.length - 1, i + 1); j++) {
        sum += envelope[j];
        count++;
      }
      smooth[i] = sum / count;
    }

    final peak = smooth.fold<double>(1e-12, math.max);
    final norm = smooth.map((v) => v / peak).toList();

    // Find a low-energy valley surrounded by energy on both sides. For an
    // utterance such as APA/ATA/AKA this tends to locate the closure rather
    // than the leading/trailing silence.
    final radius = math.max(4, (0.055 / (hop / sampleRate)).round());
    var valleyIndex = -1;
    var bestValleyScore = -double.infinity;
    for (var i = radius + 2; i < norm.length - radius - 2; i++) {
      var left = 0.0;
      var right = 0.0;
      for (var j = i - radius; j < i - 1; j++) left += norm[j];
      for (var j = i + 2; j <= i + radius; j++) right += norm[j];
      left /= math.max(1, radius - 1);
      right /= math.max(1, radius - 1);
      final surround = math.min(left, right);
      final score = surround - norm[i] - 0.12 * (left - right).abs();
      if (surround > 0.10 && score > bestValleyScore) {
        bestValleyScore = score;
        valleyIndex = i;
      }
    }
    if (valleyIndex < 0) return null;

    final searchFrames = math.max(6, (0.22 / (hop / sampleRate)).round());
    final endSearch = math.min(norm.length - 2, valleyIndex + searchFrames);
    var burstIndex = valleyIndex + 1;
    var bestRise = -double.infinity;
    for (var i = valleyIndex + 1; i <= endSearch; i++) {
      final rise = norm[i + 1] - norm[i - 1];
      final score = rise + 0.16 * norm[i + 1];
      if (score > bestRise) {
        bestRise = score;
        burstIndex = i;
      }
    }

    // Closure boundaries: use a threshold tied to the energy immediately
    // before and after the valley, capped so background noise does not create
    // an unrealistically long closure.
    final leftRef = norm[math.max(0, valleyIndex - radius)];
    final rightRef = norm[math.min(norm.length - 1, valleyIndex + radius)];
    final closureThreshold = math.min(0.36, math.max(0.08, 0.42 * math.min(leftRef, rightRef)));

    var closureStart = valleyIndex;
    while (closureStart > 1 && norm[closureStart - 1] < closureThreshold) {
      closureStart--;
    }
    var closureEnd = valleyIndex;
    while (closureEnd < norm.length - 2 && norm[closureEnd + 1] < closureThreshold) {
      closureEnd++;
    }

    final burstSample = (frameStarts[burstIndex] + frame ~/ 2)
        .clamp(0, samples.length - 1)
        .toInt();
    final closureStartSample = frameStarts[closureStart];
    final closureEndSample = (frameStarts[closureEnd] + frame)
        .clamp(0, samples.length - 1)
        .toInt();

    final burstWindowBefore = (sampleRate * 0.004).round();
    final burstWindowAfter = (sampleRate * 0.024).round();
    final burstLo = math.max(0, burstSample - burstWindowBefore);
    final burstHi = math.min(samples.length, burstSample + burstWindowAfter);
    final burstSlice = samples.sublist(burstLo, burstHi);
    final burstMetrics = _spectrumMetrics(burstSlice, maxHz: 10000);

    return StopAnalysis(
      burstTimeMs: burstSample * 1000.0 / sampleRate,
      burstCentroidHz: burstMetrics.centroidHz,
      closureDurationMs: math.max(0, closureEndSample - closureStartSample) * 1000.0 / sampleRate,
      burstStrength: bestRise.clamp(0.0, 1.0).toDouble(),
      envelope: norm,
      frameHopMs: hop * 1000.0 / sampleRate,
      burstSampleIndex: burstSample,
      closureStartSample: closureStartSample,
      closureEndSample: closureEndSample,
    );
  }

  List<double> _centerWindow(List<double> samples, int wanted) {
    if (samples.length <= wanted) return List<double>.from(samples);
    final start = math.max(0, (samples.length - wanted) ~/ 2);
    return List<double>.from(samples.sublist(start, start + wanted));
  }

  double _rms(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    var sum = 0.0;
    for (final x in samples) sum += x * x;
    return math.sqrt(sum / samples.length);
  }

  double _periodicity(List<double> input) {
    if (input.length < 512) return 0.0;

    final factor = math.max(1, sampleRate ~/ 4000);
    final rate = sampleRate / factor;
    final x = <double>[];
    for (var i = 0; i + factor <= input.length; i += factor) {
      var sum = 0.0;
      for (var j = 0; j < factor; j++) sum += input[i + j];
      x.add(sum / factor);
    }
    if (x.length < 128) return 0.0;

    final mean = x.reduce((a, b) => a + b) / x.length;
    for (var i = 0; i < x.length; i++) x[i] -= mean;

    final minLag = math.max(2, (rate / 350).floor());
    final maxLag = math.min(x.length ~/ 2, (rate / 70).ceil());
    if (maxLag <= minLag) return 0.0;

    var best = 0.0;
    for (var lag = minLag; lag <= maxLag; lag++) {
      var cross = 0.0;
      var e0 = 0.0;
      var e1 = 0.0;
      final limit = x.length - lag;
      for (var i = 0; i < limit; i++) {
        final a = x[i];
        final b = x[i + lag];
        cross += a * b;
        e0 += a * a;
        e1 += b * b;
      }
      final corr = cross / math.sqrt(e0 * e1 + 1e-15);
      if (corr > best) best = corr;
    }
    return best.clamp(0.0, 1.0).toDouble();
  }

  _SpectrumMetrics _spectrumMetrics(List<double> samples, {required double maxHz}) {
    if (samples.length < 32) {
      return const _SpectrumMetrics(0.0, 0.0, 0.0);
    }

    final wanted = math.min(samples.length, 16384);
    final x = _centerWindow(samples, wanted);
    final mean = x.reduce((a, b) => a + b) / x.length;
    final windowed = List<double>.generate(x.length, (i) {
      final w = x.length <= 1
          ? 1.0
          : 0.5 - 0.5 * math.cos(2 * math.pi * i / (x.length - 1));
      return (x[i] - mean) * w;
    });

    final fft = fftReal(windowed);
    final nyquist = sampleRate / 2.0;
    final upper = math.min(maxHz, nyquist - 80.0);

    var weighted = 0.0;
    var total = 0.0;
    var high = 0.0;
    var low = 0.0;
    for (var i = 1; i < fft.length ~/ 2; i++) {
      final f = i * sampleRate / fft.length;
      if (f > upper) break;
      final m = fft[i].magnitude;
      final p = m * m;
      if (f >= 300) {
        total += p;
        weighted += f * p;
        if (f >= 4000) high += p;
      }
      if (f >= 70 && f <= 500) low += p;
    }

    final centroid = total > 1e-15 ? weighted / total : 0.0;
    final highRatio = total > 1e-15 ? high / total : 0.0;
    final broadTotal = total + low;
    final lowRatio = broadTotal > 1e-15 ? low / broadTotal : 0.0;
    return _SpectrumMetrics(centroid, highRatio, lowRatio);
  }

  (List<double>, List<double>) _displaySpectrum(
    List<double> samples, {
    required double maxHz,
    required int bins,
  }) {
    final wanted = math.min(samples.length, 16384);
    final x = _centerWindow(samples, wanted);
    final mean = x.reduce((a, b) => a + b) / x.length;
    final windowed = List<double>.generate(x.length, (i) {
      final w = x.length <= 1
          ? 1.0
          : 0.5 - 0.5 * math.cos(2 * math.pi * i / (x.length - 1));
      return (x[i] - mean) * w;
    });
    final fft = fftReal(windowed);
    final maxIndex = math.min(
      fft.length ~/ 2 - 1,
      (math.min(maxHz, sampleRate / 2 - 80.0) * fft.length / sampleRate).floor(),
    );

    final hz = <double>[];
    final magnitude = <double>[];
    var global = 1e-12;
    for (var b = 0; b < bins; b++) {
      final lo = math.max(1, (b * maxIndex / bins).floor());
      final hi = math.max(lo + 1, ((b + 1) * maxIndex / bins).ceil());
      var power = 0.0;
      for (var i = lo; i < hi && i < fft.length ~/ 2; i++) {
        final m = fft[i].magnitude;
        power += m * m;
      }
      final value = math.sqrt(power);
      global = math.max(global, value);
      hz.add((lo + hi) * 0.5 * sampleRate / fft.length);
      magnitude.add(value);
    }
    for (var i = 0; i < magnitude.length; i++) {
      magnitude[i] = math.sqrt(magnitude[i] / global);
    }
    return (hz, magnitude);
  }
}

class _SpectrumMetrics {
  const _SpectrumMetrics(this.centroidHz, this.highFrequencyRatio, this.lowBandRatio);

  final double centroidHz;
  final double highFrequencyRatio;
  final double lowBandRatio;
}
