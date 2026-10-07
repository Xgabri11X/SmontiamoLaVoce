#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if ! command -v flutter >/dev/null 2>&1; then
  echo "Errore: Flutter non e' installato o non e' nel PATH." >&2
  echo "Installa Flutter stable e rilancia questo script." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

flutter create \
  --platforms=android \
  --org it.smontiamolavoce \
  --project-name smontiamo_la_voce \
  "$TMP/scaffold" >/dev/null

rm -rf "$ROOT/android"
cp -a "$TMP/scaffold/android" "$ROOT/android"

MANIFEST="$ROOT/android/app/src/main/AndroidManifest.xml"
python3 - "$MANIFEST" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
perm = '<uses-permission android:name="android.permission.RECORD_AUDIO" />'
if perm not in s:
    s = s.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
                  '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    ' + perm)
s = s.replace('android:label="smontiamo_la_voce"', 'android:label="Smontiamo la voce!"')
p.write_text(s)
PY

cd "$ROOT"
flutter pub get
printf '\nAndroid scaffold creato. Ora puoi eseguire: ./tools/build_apk.sh\n'
