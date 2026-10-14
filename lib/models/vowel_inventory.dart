class VowelPoint {
  const VowelPoint({
    required this.label,
    required this.f1,
    required this.f2,
    required this.example,
  });

  final String label;
  final double f1;
  final double f2;
  final String example;
}

class VowelInventory {
  const VowelInventory({
    required this.code,
    required this.name,
    required this.points,
    required this.note,
  });

  final String code;
  final String name;
  final List<VowelPoint> points;
  final String note;
}

const italianVowels = <VowelPoint>[
  VowelPoint(label: 'i', f1: 300, f2: 2300, example: 'vino'),
  VowelPoint(label: 'e', f1: 430, f2: 2050, example: 'sera'),
  VowelPoint(label: 'a', f1: 750, f2: 1300, example: 'casa'),
  VowelPoint(label: 'o', f1: 450, f2: 900, example: 'sole'),
  VowelPoint(label: 'u', f1: 320, f2: 700, example: 'luna'),
];

// Static monophthong targets chosen for a clear classroom comparison in the
// F1-F2 plane. They are deliberately approximate: real formants depend on
// speaker, dialect, phonetic context and normalization convention.
const englishVowels = <VowelPoint>[
  VowelPoint(label: 'iː', f1: 300, f2: 2350, example: 'see'),
  VowelPoint(label: 'ɪ', f1: 400, f2: 2000, example: 'sit'),
  VowelPoint(label: 'ɛ', f1: 530, f2: 1750, example: 'bed'),
  VowelPoint(label: 'æ', f1: 700, f2: 1700, example: 'cat'),
  VowelPoint(label: 'ə', f1: 500, f2: 1500, example: 'about'),
  VowelPoint(label: 'ʌ', f1: 600, f2: 1250, example: 'cup'),
  VowelPoint(label: 'ɑː', f1: 750, f2: 1100, example: 'father'),
  VowelPoint(label: 'ɔː', f1: 500, f2: 900, example: 'thought'),
  VowelPoint(label: 'ʊ', f1: 430, f2: 1050, example: 'book'),
  VowelPoint(label: 'uː', f1: 330, f2: 850, example: 'food'),
];

const frenchVowels = <VowelPoint>[
  VowelPoint(label: 'i', f1: 300, f2: 2400, example: 'si'),
  VowelPoint(label: 'e', f1: 400, f2: 2100, example: 'été'),
  VowelPoint(label: 'ɛ', f1: 550, f2: 1900, example: 'mère'),
  VowelPoint(label: 'a', f1: 700, f2: 1400, example: 'patte'),
  VowelPoint(label: 'y', f1: 300, f2: 1700, example: 'tu'),
  VowelPoint(label: 'ø', f1: 400, f2: 1550, example: 'peu'),
  VowelPoint(label: 'œ', f1: 550, f2: 1450, example: 'peur'),
  VowelPoint(label: 'ə', f1: 450, f2: 1450, example: 'le'),
  VowelPoint(label: 'u', f1: 300, f2: 800, example: 'tout'),
  VowelPoint(label: 'o', f1: 400, f2: 900, example: 'beau'),
  VowelPoint(label: 'ɔ', f1: 550, f2: 1000, example: 'porte'),
];

const germanVowels = <VowelPoint>[
  VowelPoint(label: 'iː', f1: 280, f2: 2350, example: 'Biene'),
  VowelPoint(label: 'ɪ', f1: 390, f2: 2000, example: 'bitte'),
  VowelPoint(label: 'eː', f1: 390, f2: 2100, example: 'See'),
  VowelPoint(label: 'ɛ', f1: 540, f2: 1850, example: 'Bett'),
  VowelPoint(label: 'aː', f1: 700, f2: 1300, example: 'Tag'),
  VowelPoint(label: 'yː', f1: 300, f2: 1700, example: 'Tür'),
  VowelPoint(label: 'ʏ', f1: 410, f2: 1550, example: 'fünf'),
  VowelPoint(label: 'øː', f1: 400, f2: 1500, example: 'schön'),
  VowelPoint(label: 'œ', f1: 550, f2: 1400, example: 'Hölle'),
  VowelPoint(label: 'uː', f1: 300, f2: 750, example: 'gut'),
  VowelPoint(label: 'ʊ', f1: 410, f2: 900, example: 'Mutter'),
  VowelPoint(label: 'oː', f1: 400, f2: 850, example: 'Brot'),
  VowelPoint(label: 'ɔ', f1: 550, f2: 950, example: 'Gott'),
  VowelPoint(label: 'ə', f1: 500, f2: 1500, example: 'bitte (finale)'),
];

const vowelInventories = <VowelInventory>[
  VowelInventory(
    code: 'it',
    name: 'Italiano',
    points: italianVowels,
    note: 'Cinque target semplici A/E/I/O/U, coerenti con il riconoscimento automatico dell’app.',
  ),
  VowelInventory(
    code: 'en',
    name: 'English',
    points: englishVowels,
    note: 'Target monottongali indicativi. L’inglese varia molto tra accenti e diversi dittonghi richiederebbero una traiettoria, non un solo punto F1–F2.',
  ),
  VowelInventory(
    code: 'fr',
    name: 'Français',
    points: frenchVowels,
    note: 'Sono mostrate le principali vocali orali. Le vocali nasali francesi richiedono parametri acustici aggiuntivi oltre a F1 e F2.',
  ),
  VowelInventory(
    code: 'de',
    name: 'Deutsch',
    points: germanVowels,
    note: 'Target indicativi delle principali vocali. Durata e qualità lavorano insieme in molte opposizioni del tedesco.',
  ),
];
