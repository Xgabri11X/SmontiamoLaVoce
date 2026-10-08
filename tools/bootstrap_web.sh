#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Creo/aggiorno il target Flutter Web"
flutter create . --platforms=web

echo "==> Personalizzo titolo e manifest"
python3 - <<'PY'
from pathlib import Path
import json, re

index = Path('web/index.html')
text = index.read_text(encoding='utf-8')
text = re.sub(r'<title>.*?</title>', '<title>Smontiamo la voce!</title>', text, flags=re.S)
if '<meta name="description"' not in text:
    text = text.replace(
        '<head>',
        '<head>\n  <meta name="description" content="Laboratorio interattivo su suono, Fourier, armoniche e vocali.">',
        1,
    )
index.write_text(text, encoding='utf-8')

manifest = Path('web/manifest.json')
if manifest.exists():
    data = json.loads(manifest.read_text(encoding='utf-8'))
    data['name'] = 'Smontiamo la voce!'
    data['short_name'] = 'Smontiamo la voce!'
    data['description'] = 'Laboratorio interattivo su suono, Fourier, armoniche e vocali.'
    data['display'] = 'standalone'
    data['background_color'] = '#071521'
    data['theme_color'] = '#071521'
    manifest.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
PY

echo "Target web pronto. Per provarlo: flutter run -d chrome"
