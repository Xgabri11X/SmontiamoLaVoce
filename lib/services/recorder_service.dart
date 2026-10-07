import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

class RecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  final List<double> _samples = <double>[];
  int sampleRate = 44100;
  bool isRecording = false;

  List<double> get samples => List<double>.unmodifiable(_samples);

  Future<bool> start({void Function(List<double> latest)? onChunk}) async {
    if (!await _recorder.hasPermission()) return false;
    _samples.clear();
    final stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
        streamBufferSize: 4096,
      ),
    );
    isRecording = true;
    _subscription = stream.listen((bytes) {
      final data = ByteData.sublistView(bytes);
      final chunk = <double>[];
      for (var i = 0; i + 1 < bytes.length; i += 2) {
        final value = data.getInt16(i, Endian.little) / 32768.0;
        _samples.add(value);
        chunk.add(value);
      }
      if (chunk.isNotEmpty) onChunk?.call(chunk);
    });
    return true;
  }

  Future<List<double>> stop() async {
    if (!isRecording) return samples;
    await _recorder.stop();
    await _subscription?.cancel();
    _subscription = null;
    isRecording = false;
    return samples;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _recorder.dispose();
  }
}
