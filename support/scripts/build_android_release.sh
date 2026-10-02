#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../app"
flutter pub get
(cd ../packages/localsend_isolates && flutter_rust_bridge_codegen generate)
dart run slang
dart run build_runner build
flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64 --obfuscate --split-debug-info=build/symbols
