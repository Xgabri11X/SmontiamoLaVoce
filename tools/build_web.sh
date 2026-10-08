#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -d web ]]; then
  ./tools/bootstrap_web.sh
fi

flutter pub get
flutter test

BASE_HREF="${1:-/SmontiamoLaVoce/}"
echo "==> Build web con base href: $BASE_HREF"
flutter build web --release --base-href "$BASE_HREF"

echo
echo "Build pronta in: build/web"
echo "Per GitHub Pages usa normalmente: /SmontiamoLaVoce/"
