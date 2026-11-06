#!/usr/bin/env bash
set -euo pipefail

TERAI_PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
TERAI_FLUTTER_ROOT="$(cd "$TERAI_PROJECT_DIR/../flutter" && pwd)"
TERAI_CONFIG_FILE="$TERAI_PROJECT_DIR/.env.web"

if [[ ! -f "$TERAI_CONFIG_FILE" ]]; then
  echo "Missing .env.web. Copy .env.example to .env.web and add only SUPABASE_URL and SUPABASE_ANON_KEY."
  exit 1
fi

cd "$TERAI_PROJECT_DIR"
"$TERAI_FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart" \
  "$TERAI_FLUTTER_ROOT/packages/flutter_tools/bin/flutter_tools.dart" \
  run -d chrome --dart-define-from-file="$TERAI_CONFIG_FILE" "$@"
