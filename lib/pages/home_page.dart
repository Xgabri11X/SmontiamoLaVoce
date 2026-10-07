import 'package:flutter/material.dart';

import '../models/lab_session.dart';
import 'harmonics_page.dart';
import 'record_page.dart';
import 'vowel_space_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final session = LabSession.instance;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text(
              'SMONTIAMO\nLA VOCE!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    letterSpacing: -1.2,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Gioca con onde, armoniche e vocali.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 26),
            _HeroCard(
              icon: Icons.mic_rounded,
              title: '1 · Registra una vocale',
              subtitle: 'Scegli A, E, I, O o U: l’app prova a riconoscerla e misura la fondamentale.',
              onTap: () => _push(context, const RecordPage()),
            ),
            const SizedBox(height: 12),
            _HeroCard(
              icon: Icons.graphic_eq_rounded,
              title: '2 · Smontala con Fourier',
              subtitle: 'Esplora le prime armoniche; la ricostruzione completa arriva fino a 20 kHz.',
              onTap: () => _push(context, const HarmonicsPage()),
            ),
            const SizedBox(height: 12),
            _HeroCard(
              icon: Icons.face_rounded,
              title: '3 · Muovi la vocale',
              subtitle: 'Parti dalla vocale riconosciuta e trascina F1 e F2 guardando lingua e bocca.',
              onTap: () => _push(context, const VowelSpacePage()),
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Color(0xFF58D5E8)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tutto avviene sul dispositivo: la registrazione non viene inviata a nessun server.${session.hasRecording ? ' Hai già una registrazione pronta.' : ''}',
                        style: const TextStyle(color: Colors.white70, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF58D5E8).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF58D5E8), size: 29),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 5),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, height: 1.3)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
