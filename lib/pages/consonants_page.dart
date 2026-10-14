import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../dsp/audio_synth.dart';
import '../dsp/consonant_analyzer.dart';
import '../services/recorder_service.dart';
import '../widgets/burst_waveform_painter.dart';
import '../widgets/spectrum_painter.dart';
import '../widgets/waveform_painter.dart';

enum _ConsonantMode { fricative, stop }
enum _FricativePlace { labiodental, alveolar, postalveolar }

class ConsonantsPage extends StatefulWidget {
  const ConsonantsPage({super.key});

  @override
  State<ConsonantsPage> createState() => _ConsonantsPageState();
}

class _ConsonantsPageState extends State<ConsonantsPage> {
  final RecorderService _recorder = RecorderService();
  final AudioPlayer _player = AudioPlayer();

  _ConsonantMode _mode = _ConsonantMode.fricative;
  _FricativePlace _place = _FricativePlace.alveolar;
  bool _voiced = false;
  bool _recording = false;
  bool _busy = false;
  List<double> _live = <double>[];
  List<double> _samples = <double>[];
  FricativeAnalysis? _fricative;
  StopAnalysis? _stop;
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
      try {
        final data = await _recorder.stop();
        if (!mounted) return;
        final analyzer = ConsonantAnalyzer(_recorder.sampleRate);
        setState(() {
          _samples = List<double>.from(data);
          _recording = false;
          _busy = false;
          _fricative = null;
          _stop = null;
          if (_mode == _ConsonantMode.fricative) {
            _fricative = analyzer.analyzeFricative(data);
            _message = _fricative == null
                ? 'Segnale troppo breve o debole. Tieni la consonante per circa 2 secondi.'
                : null;
          } else {
            _stop = analyzer.analyzeStop(data);
            _message = _stop == null
                ? 'Non trovo bene la sequenza vocale–chiusura–vocale. Prova lentamente: A–P–A, A–T–A o A–K–A.'
                : null;
          }
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _recording = false;
          _busy = false;
          _message = 'Non sono riuscito a terminare la registrazione.';
        });
      }
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
      _live = <double>[];
      _samples = <double>[];
      _fricative = null;
      _stop = null;
    });

    try {
      final ok = await _recorder.start(onChunk: (chunk) {
        if (!mounted) return;
        setState(() {
          _live.addAll(chunk);
          if (_live.length > 2400) {
            _live = _live.sublist(_live.length - 2400);
          }
        });
      });
      if (!mounted) return;
      setState(() {
        _busy = false;
        _recording = ok;
        if (!ok) _message = 'Serve il permesso per usare il microfono.';
      });
      if (ok) {
        final seconds = _mode == _ConsonantMode.fricative ? 3 : 4;
        _autoStop = Timer(Duration(seconds: seconds), () {
          if (mounted && _recording) _toggleRecord();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _recording = false;
        _message = 'Il browser non è riuscito ad aprire il microfono.';
      });
    }
  }

  Future<void> _playOriginal() async {
    if (_samples.isEmpty) return;
    final wav = AudioSynth.wavFromSamples(_samples, _recorder.sampleRate);
    await _player.stop();
    await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
  }

  Future<void> _playFricative() async {
    final wav = AudioSynth.fricativeWav(
      place: _place.name,
      voiced: _voiced,
      sampleRate: _recorder.sampleRate,
    );
    await _player.stop();
    await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
  }

  String get _syntheticSymbol {
    switch (_place) {
      case _FricativePlace.labiodental:
        return _voiced ? 'V' : 'F';
      case _FricativePlace.alveolar:
        return _voiced ? 'Z' : 'S';
      case _FricativePlace.postalveolar:
        return _voiced ? 'ʒ' : 'SC / ʃ';
    }
  }

  String get _placeLabel {
    switch (_place) {
      case _FricativePlace.labiodental:
        return 'Labbro + denti';
      case _FricativePlace.alveolar:
        return 'Lingua + alveoli';
      case _FricativePlace.postalveolar:
        return 'Dietro gli alveoli';
    }
  }

  void _changeMode(_ConsonantMode mode) {
    if (_recording || _busy || mode == _mode) return;
    setState(() {
      _mode = mode;
      _samples = <double>[];
      _live = <double>[];
      _fricative = null;
      _stop = null;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Costruiamo le consonanti')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
        children: [
          const Text(
            'Le vocali cambiano soprattutto le risonanze. Nelle consonanti entrano in gioco anche rumore, restringimenti e chiusure del flusso d’aria.',
            style: TextStyle(fontSize: 16, height: 1.35, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ChoiceChip(
                selected: _mode == _ConsonantMode.fricative,
                onSelected: (_) => _changeMode(_ConsonantMode.fricative),
                avatar: const Icon(Icons.air_rounded, size: 18),
                label: const Text('Fricative · S Z F V'),
              ),
              ChoiceChip(
                selected: _mode == _ConsonantMode.stop,
                onSelected: (_) => _changeMode(_ConsonantMode.stop),
                avatar: const Icon(Icons.flash_on_rounded, size: 18),
                label: const Text('Occlusive · P T K'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_mode == _ConsonantMode.fricative)
            _buildFricativeLab(context)
          else
            _buildStopLab(context),
        ],
      ),
    );
  }

  Widget _buildFricativeLab(BuildContext context) {
    final wave = _recording ? _live : _samples.take(3200).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          title: '1 · Rumore + voce',
          subtitle: 'Tieni SSS, ZZZ, FFF, VVV oppure SC/ʃ per circa 2 secondi. Prova prima S e poi Z senza cambiare la posizione della lingua.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 118,
              child: CustomPaint(
                painter: WaveformPainter(wave),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _toggleRecord,
          icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded),
          label: Text(_recording ? 'FERMA E ANALIZZA' : 'REGISTRA UNA FRICATIVA'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 10),
          Text(_message!, style: const TextStyle(color: Color(0xFFFFC36A))),
        ],
        if (_samples.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _playOriginal,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Riascolta la registrazione'),
          ),
        ],
        if (_fricative != null) ...[
          const SizedBox(height: 16),
          _FricativeResultCard(result: _fricative!),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spettro del rumore',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'La posizione orizzontale indica dove si concentra l’energia: /s/ tende verso frequenze più alte di /ʃ/.',
                    style: TextStyle(color: Colors.white70, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 145,
                    child: CustomPaint(
                      painter: SpectrumPainter(_fricative!.spectrumMagnitude),
                      size: Size.infinite,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0 kHz', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text('5 kHz', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        Text('10 kHz', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        const _SectionTitle(
          title: '2 · Costruiscila',
          subtitle: 'Scegli dove restringere il canale e poi “accendi” o “spegni” le corde vocali. La sintesi è volutamente semplice: serve a isolare i due ingredienti fisici.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<_FricativePlace>(
                  initialValue: _place,
                  decoration: const InputDecoration(
                    labelText: 'Punto di restringimento',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: _FricativePlace.labiodental,
                      child: Text('Labbro + denti · F / V'),
                    ),
                    DropdownMenuItem(
                      value: _FricativePlace.alveolar,
                      child: Text('Lingua + alveoli · S / Z'),
                    ),
                    DropdownMenuItem(
                      value: _FricativePlace.postalveolar,
                      child: Text('Dietro gli alveoli · SC / ʃ'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _place = value);
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Corde vocali'),
                  subtitle: Text(_voiced ? 'ON · componente periodica' : 'OFF · solo rumore'),
                  value: _voiced,
                  onChanged: (value) => setState(() => _voiced = value),
                ),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF071521).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _syntheticSymbol,
                        style: const TextStyle(
                          color: Color(0xFF58D5E8),
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          '$_placeLabel · ${_voiced ? 'voce ON' : 'voce OFF'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _playFricative,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text('ASCOLTA $_syntheticSymbol'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _InfoBox(
          text: 'Esperimento lampo: pronuncia SSSSS e, senza muovere lingua o denti, fai vibrare le corde vocali. Diventa ZZZZZ. Sullo spettro compare una componente periodica a bassa frequenza.',
        ),
      ],
    );
  }

  Widget _buildStopLab(BuildContext context) {
    final wave = _recording ? _live : _samples;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          title: 'Chiusura → burst → vocale',
          subtitle: 'Pronuncia lentamente APA, ATA oppure AKA una sola volta. Durante P/T/K il flusso si chiude; alla riapertura compare un transitorio molto breve: il burst.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 135,
              child: _stop == null
                  ? CustomPaint(
                      painter: WaveformPainter(wave),
                      size: Size.infinite,
                    )
                  : CustomPaint(
                      painter: BurstWaveformPainter(
                        samples: _samples,
                        burstSampleIndex: _stop!.burstSampleIndex,
                        closureStartSample: _stop!.closureStartSample,
                        closureEndSample: _stop!.closureEndSample,
                      ),
                      size: Size.infinite,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _toggleRecord,
          icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded),
          label: Text(_recording ? 'FERMA E ANALIZZA' : 'REGISTRA APA / ATA / AKA'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 10),
          Text(_message!, style: const TextStyle(color: Color(0xFFFFC36A))),
        ],
        if (_samples.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _playOriginal,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Riascolta la registrazione'),
          ),
        ],
        if (_stop != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Il transitorio',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetricTile(
                        value: '${_stop!.burstTimeMs.round()} ms',
                        label: 'BURST NELLA REGISTRAZIONE',
                      ),
                      _MetricTile(
                        value: '${_stop!.closureDurationMs.round()} ms',
                        label: 'CHIUSURA STIMATA',
                      ),
                      _MetricTile(
                        value: '${(_stop!.burstCentroidHz / 1000).toStringAsFixed(1)} kHz',
                        label: 'CENTROIDE DEL BURST',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'La fascia gialla indica la zona di bassa energia associata alla chiusura; la linea rossa marca la riapertura più brusca trovata dall’app.',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _InfoBox(
            text: 'Confronta P, T e K più volte. Il luogo di articolazione cambia lo spettro del burst, ma questa versione non forza un riconoscimento P/T/K: telefono, vocale e parlante influenzano molto il risultato.',
          ),
        ],
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Dove avviene la chiusura?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                SizedBox(height: 10),
                _PlaceRow(symbol: 'P', text: 'labbra · bilabiale'),
                _PlaceRow(symbol: 'T', text: 'denti/alveoli · coronale'),
                _PlaceRow(symbol: 'K', text: 'dorso della lingua + velo · velare'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FricativeResultCard extends StatelessWidget {
  const _FricativeResultCard({required this.result});

  final FricativeAnalysis result;

  @override
  Widget build(BuildContext context) {
    final voicePercent = (result.voicing * 100).round();
    final centroidK = result.centroidHz / 1000.0;
    final centroidScale = ((result.centroidHz - 1000) / 8000).clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profilo più vicino', style: TextStyle(color: Colors.white60)),
                      const SizedBox(height: 3),
                      Text(
                        result.closestProfile,
                        style: const TextStyle(
                          color: Color(0xFF58D5E8),
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        ),
                      ),
                      Text(result.profileFamily, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                _MetricTile(value: '$voicePercent%', label: 'VOICING'),
              ],
            ),
            const SizedBox(height: 15),
            Text('Corde vocali · $voicePercent%', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: result.voicing, minHeight: 8),
            const SizedBox(height: 14),
            Text(
              'Centro dello spettro · ${centroidK.toStringAsFixed(1)} kHz',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: centroidScale, minHeight: 8),
            const SizedBox(height: 12),
            const Text(
              'Il nome è solo un profilo didattico: il dato fisico importante è vedere separatamente periodicità e distribuzione del rumore.',
              style: TextStyle(color: Colors.white60, height: 1.3, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF071521).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Colors.white70, height: 1.35)),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF58D5E8).withValues(alpha: 0.09),
        border: Border.all(color: const Color(0xFF58D5E8).withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science_outlined, color: Color(0xFF58D5E8)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.symbol, required this.text});
  final String symbol;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF58D5E8).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(symbol, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF58D5E8))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
