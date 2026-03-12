#!/usr/bin/env bash
set -euo pipefail

FLUTTER_ROOT="$PWD/.flutter-sdk"

if [ ! -d "$FLUTTER_ROOT" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get

BUILD_CMD=(
  flutter build web --release
)

if [ -n "${SIGNBRIDGE_API_URL:-}" ]; then
  BUILD_CMD+=(--dart-define="SIGNBRIDGE_API_URL=${SIGNBRIDGE_API_URL}")
fi

if [ -n "${SIGNBRIDGE_API_KEY:-}" ]; then
  BUILD_CMD+=(--dart-define="SIGNBRIDGE_API_KEY=${SIGNBRIDGE_API_KEY}")
fi

"${BUILD_CMD[@]}"
