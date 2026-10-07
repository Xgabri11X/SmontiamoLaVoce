#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
if [ ! -d android ]; then
  ./tools/bootstrap_android.sh
fi
flutter pub get
flutter test
flutter build apk --release
APK="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK" ]; then
  cp "$APK" "$ROOT/SmontiamoLaVoce.apk"
  echo "APK pronto: $ROOT/SmontiamoLaVoce.apk"
fi
