import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dsp/audio_synth.dart';
import '../models/lab_session.dart';
import '../services/player_service.dart';
import '../widgets/harmonic_bars.dart';
import 'record_page.dart';
import 'vowel_space_page.dart';

class HarmonicsPage extends StatefulWidget {
  const HarmonicsPage({super.key});

  @override
  State<HarmonicsPage> createState() => _HarmonicsPageState();
}

class _HarmonicsPageState extends State<HarmonicsPage> {
  static const int _maxVisibleHarmonics = 24;
  final _player = PlayerService();
  late List<bool> enabled;

  @override
  void initState() {
    super.initState();
    final n = LabSession.instance.harmonics.isEmpty ? 16 : LabSession.instance.harmonics.length;
    enabled = List<bool>.filled(n, true);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final s = LabSession.instance;
    if (!s.hasAnalysis) return;
    final wav = AudioSynth.harmonicWav(
      f0: s.f0!,
      amplitudes: s.harmonics,
      enabled: enabled,
      sampleRate: s.sampleRate,
    );
    await _player.playWav(wav);
  }

  @override
  Widget build(BuildContext context) {
    final s = LabSession.instance;
    if (!s.hasAnalysis) {
      return Scaffold(
        appBar: AppBar(title: const Text('Smontala con Fourier')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mic_none_rounded, size: 54, color: Color(0xFF58D5E8)),
                const SizedBox(height: 14),
                const Text(
                  'Prima registriamo una voce.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecordPage()),
                  ),
                  child: const Text('VAI AL MICROFONO'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final visible = math.min(_maxVisibleHarmonics, s.harmonics.length);
    final highestHz = s.harmonics.length * s.f0!;

    return Scaffold(
      appBar: AppBar(title: const Text('Smontala con Fourier')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'f₀ = ${s.f0!.toStringAsFixed(1)} Hz',
            style: const TextStyle(
              color: Color(0xFF58D5E8),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Ogni barra è una componente della tua voce. Tocca una barra per spegnerla o riaccenderla.',
            style: TextStyle(fontSize: 17, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            'La ricostruzione usa ${s.harmonics.length} armoniche fino a ${(highestHz / 1000).toStringAsFixed(1)} kHz. '
            'Per mantenere il grafico leggibile mostriamo solo le prime $visible.',
            style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
              child: HarmonicBars(
                amplitudes: s.harmonics.take(visible).toList(),
                enabled: enabled.take(visible).toList(),
                onToggle: (i) => setState(() => enabled[i] = !enabled[i]),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => setState(() {
                  enabled = List<bool>.filled(enabled.length, false);
                  enabled[0] = true;
                }),
                child: const Text('SOLO H1'),
              ),
              OutlinedButton(
                onPressed: () => setState(() {
                  final next = enabled.indexWhere((e) => !e);
                  if (next >= 0) enabled[next] = true;
                }),
                child: const Text('+ 1 ARMONICA'),
              ),
              OutlinedButton(
                onPressed: () => setState(() => enabled = List<bool>.filled(enabled.length, true)),
                child: const Text('TUTTE · 20 kHz'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _play,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('ASCOLTA LA RICOSTRUZIONE'),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Idea chiave\n',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const TextSpan(
                      text: 'La fondamentale determina soprattutto l’altezza. La distribuzione delle armoniche contribuisce al ',
                    ),
                    TextSpan(
                      text: 'timbro',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VowelSpacePage()),
            ),
            icon: const Icon(Icons.face_rounded),
            label: const Text('ORA CAMBIAMO LA BOCCA'),
          ),
        ],
      ),
    );
  }
}
