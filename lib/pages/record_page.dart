import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../dsp/audio_synth.dart';
import '../models/lab_session.dart';
import '../services/recorder_service.dart';
import '../widgets/spectrum_painter.dart';
import '../widgets/waveform_painter.dart';
import 'harmonics_page.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final _recorder = RecorderService();
  final _player = AudioPlayer();
  List<double> _live = <double>[];
  bool _recording = false;
  bool _busy = false;
  String? _message;
  Timer? _autoStop;

  @override
  void dispose() {
    _autoStop?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_busy) return;
    if (_recording) {
      _autoStop?.cancel();
      _autoStop = null;
      setState(() => _busy = true);
      final data = await _recorder.stop();
      LabSession.instance.setRecording(data, _recorder.sampleRate);
      if (mounted) {
        final s = LabSession.instance;
        setState(() {
          _recording = false;
          _busy = false;
          if (data.length < 4000) {
            _message = 'Registrazione troppo breve: prova per almeno 2 secondi.';
          } else if (!s.hasAnalysis) {
            _message = 'Non riesco a trovare una nota stabile. Prova a tenere la vocale più ferma.';
          } else {
            _message = null;
          }
        });
      }
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
      _live = <double>[];
    });
    final ok = await _recorder.start(onChunk: (chunk) {
      if (!mounted) return;
      setState(() {
        _live.addAll(chunk);
        if (_live.length > 1600) _live = _live.sublist(_live.length - 1600);
      });
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      _recording = ok;
      if (ok) {
        _autoStop = Timer(const Duration(seconds: 4), () {
          if (mounted && _recording) _toggleRecord();
        });
      }
      if (!ok) _message = 'Serve il permesso per usare il microfono.';
    });
  }

  Future<void> _playOriginal() async {
    final session = LabSession.instance;
    if (!session.hasRecording) return;
    final wav = AudioSynth.wavFromSamples(session.samples, session.sampleRate);
    await _player.stop();
    await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
  }

  String _noteName(double f) {
    const names = ['C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B'];
    final midi = (69 + 12 * (math.log(f / 440) / math.ln2)).round();
    return '${names[((midi % 12) + 12) % 12]}${midi ~/ 12 - 1}';
  }

  @override
  Widget build(BuildContext context) {
    final session = LabSession.instance;
    final wave = _recording ? _live : session.samples.take(2600).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Registra una vocale')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Scegli una vocale e tienila stabile per 2–3 secondi.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Puoi usare A, E, I, O oppure U. Mantieni soprattutto la stessa nota.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 155,
                child: CustomPaint(painter: WaveformPainter(wave), size: Size.infinite),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _toggleRecord,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded),
            label: Text(_recording ? 'STOP E ANALIZZA' : 'REGISTRA UNA VOCALE'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 10),
            Text(_message!, style: const TextStyle(color: Colors.orangeAccent)),
          ],
          if (session.hasAnalysis) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Fondamentale',
                    value: '${session.f0!.toStringAsFixed(1)} Hz',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _Metric(label: 'Nota circa', value: _noteName(session.f0!))),
              ],
            ),
            if (session.vowel != null) ...[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.record_voice_over_rounded, color: Color(0xFF58D5E8), size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Vocale riconosciuta', style: TextStyle(color: Colors.white60, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              session.vowel!.label,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Partiremo da questa zona nel trapezio F1–F2.',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.68), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Spettro · 0–5 kHz', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 155,
                      child: CustomPaint(
                        painter: SpectrumPainter(session.spectrumMagnitude),
                        size: Size.infinite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _playOriginal,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('ASCOLTA'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HarmonicsPage()),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('SMONTALA'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
