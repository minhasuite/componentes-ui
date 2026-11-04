#!/usr/bin/env bash
# Compila a vitrine para web (container) e serve em http://localhost:${PORTA:-3910}.
# Uso (em componentes-ui/flutter): example/tool/vitrine.sh   | SO_BUILD=1 example/tool/vitrine.sh
set -e
cd "$(dirname "$0")/../.."
podman run --rm -v "$PWD":/app -v flutter_pub:/root/.pub-cache -w /app/example ghcr.io/cirruslabs/flutter:stable \
  bash -lc 'flutter pub get >/dev/null && flutter build web --release --no-web-resources-cdn 2>&1 | tail -3'
[ -n "$SO_BUILD" ] && exit 0
echo "Vitrine em http://localhost:${PORTA:-3910}"
exec python3 -m http.server "${PORTA:-3910}" -d example/build/web
