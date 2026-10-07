import '../dsp/spectral_analyzer.dart';

class LabSession {
  LabSession._();
  static final LabSession instance = LabSession._();

  int sampleRate = 44100;
  List<double> samples = <double>[];
  double? f0;
  List<double> harmonics = <double>[];
  List<double> spectrumHz = <double>[];
  List<double> spectrumMagnitude = <double>[];
  VowelEstimate? vowel;

  bool get hasRecording => samples.isNotEmpty;
  bool get hasAnalysis => f0 != null && harmonics.isNotEmpty;

  void clear() {
    samples = <double>[];
    f0 = null;
    harmonics = <double>[];
    spectrumHz = <double>[];
    spectrumMagnitude = <double>[];
    vowel = null;
  }

  void setRecording(List<double> data, int rate) {
    samples = List<double>.from(data);
    sampleRate = rate;
    analyze();
  }

  void analyze() {
    vowel = null;
    if (samples.length < 2048) return;
    final analyzer = SpectralAnalyzer(sampleRate);
    f0 = analyzer.estimatePitch(samples);
    final spec = analyzer.spectrum(samples, maxHz: 5000, bins: 180);
    spectrumHz = spec.$1;
    spectrumMagnitude = spec.$2;
    if (f0 != null) {
      final count = analyzer.harmonicCountTo(f0!);
      harmonics = analyzer.harmonicAmplitudes(samples, f0!, count: count);
      vowel = analyzer.estimateVowel(samples, f0!);
    }
  }
}
