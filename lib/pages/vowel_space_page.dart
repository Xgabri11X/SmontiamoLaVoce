import 'package:flutter/material.dart';

import '../dsp/audio_synth.dart';
import '../models/lab_session.dart';
import '../models/vowel_inventory.dart';
import '../services/player_service.dart';
import '../widgets/mouth_painter.dart';
import '../widgets/vowel_space_painter.dart';

class VowelSpacePage extends StatefulWidget {
  const VowelSpacePage({super.key});

  @override
  State<VowelSpacePage> createState() => _VowelSpacePageState();
}

class _VowelSpacePageState extends State<VowelSpacePage> {
  final _player = PlayerService();
  late double f1;
  late double f2;
  late bool useNatural;
  String? detectedLabel;
  VowelPoint? selectedPreset;
  VowelInventory inventory = vowelInventories.first;

  @override
  void initState() {
    super.initState();
    final session = LabSession.instance;
    final detected = session.vowel;
    f1 = detected?.f1 ?? 750;
    f2 = detected?.f2 ?? 1300;
    detectedLabel = detected?.label;
    useNatural = session.hasRecording;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  double get _pitch =>
      (LabSession.instance.f0?.clamp(110.0, 260.0) ?? 180.0).toDouble();

  Future<void> _play() async {
    final session = LabSession.instance;
    final wav = useNatural && session.hasRecording
        ? AudioSynth.lpcNaturalVowelWav(
            source: session.samples,
            sourceSampleRate: session.sampleRate,
            f1: f1,
            f2: f2,
          )
        : AudioSynth.vowelWav(f0: _pitch, f1: f1, f2: f2);
    await _player.playWav(wav);
  }

  void _setFromPoint(VowelPoint point) {
    setState(() {
      f1 = point.f1;
      f2 = point.f2;
      selectedPreset = point;
      detectedLabel = null;
    });
    _play();
  }

  void _setInventory(VowelInventory next) {
    setState(() {
      inventory = next;
      selectedPreset = null;
      // Keep the physical F1-F2 position fixed so students can compare where
      // the same sound falls relative to different language inventories.
      if (next.code != 'it') detectedLabel = null;
    });
  }

  void _moveTo(Offset localPosition, Size size) {
    final values = offsetToFormants(size, localPosition);
    setState(() {
      f1 = values.$1;
      f2 = values.$2;
      selectedPreset = null;
      detectedLabel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Muovi la vocale')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (detectedLabel != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF58D5E8),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Hai registrato una $detectedLabel: partiamo automaticamente dalla sua zona nel trapezio italiano.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'La voce è uno strumento con una cassa di risonanza che possiamo cambiare.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Trascina il punto. F1 segue soprattutto apertura/altezza della lingua; F2 segue soprattutto la posizione avanti–indietro.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 16),
          const Text(
            'Confronta le lingue',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vowelInventories.map((item) {
              return ChoiceChip(
                label: Text(item.name),
                selected: item.code == inventory.code,
                onSelected: (_) => _setInventory(item),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            inventory.note,
            style: const TextStyle(color: Colors.white60, height: 1.3),
          ),
          const SizedBox(height: 14),
          if (LabSession.instance.hasRecording)
            SwitchListTile.adaptive(
              value: useNatural,
              onChanged: (v) => setState(() => useNatural = v),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text(
                'Usa la mia voce',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'LPC: conserva la sorgente reale e cambia soprattutto le risonanze.',
              ),
            ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Spazio vocalico · ${inventory.name}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      const Text(
                        '← F2 alto · F2 basso →',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 300,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final size = Size(c.maxWidth, c.maxHeight);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanDown: (d) => _moveTo(d.localPosition, size),
                          onPanUpdate: (d) => _moveTo(d.localPosition, size),
                          onPanEnd: (_) => _play(),
                          onTapUp: (d) {
                            _moveTo(d.localPosition, size);
                            _play();
                          },
                          child: CustomPaint(
                            painter: VowelSpacePainter(
                              f1: f1,
                              f2: f2,
                              points: inventory.points,
                            ),
                            size: Size.infinite,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'F1 ${f1.round()} Hz',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'F2 ${f2.round()} Hz',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  if (selectedPreset != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${selectedPreset!.label} · esempio: ${selectedPreset!.example}',
                      style: const TextStyle(
                        color: Color(0xFFFFC777),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bocca e lingua · schema didattico',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 230,
                    child: CustomPaint(
                      painter: MouthPainter(f1: f1, f2: f2),
                      size: Size.infinite,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vocali di riferimento · ${inventory.name}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: inventory.points
                .map(
                  (v) => OutlinedButton(
                    onPressed: () => _setFromPoint(v),
                    child: Text('${v.label} · ${v.example}'),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _play,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('ASCOLTA QUESTA POSIZIONE'),
          ),
          const SizedBox(height: 18),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'I punti delle lingue sono target didattici indicativi, non valori universali: F1 e F2 cambiano con parlante, accento e contesto. Il riconoscimento automatico iniziale resta volutamente limitato alle cinque vocali italiane A/E/I/O/U. I dittonghi richiedono una traiettoria nel tempo e le vocali nasali anche informazioni acustiche oltre a F1 e F2.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
