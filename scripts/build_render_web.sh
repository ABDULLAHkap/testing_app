#!/usr/bin/env bash
set -euo pipefail

# Render does not include Flutter in its static-site image. Install a shallow
# stable SDK in the disposable build workspace, then compile the web frontend.
render_flutter_dir="${RENDER_FLUTTER_DIR:-/tmp/render-flutter-sdk}"
render_pub_cache="${RENDER_PUB_CACHE:-/tmp/render-pub-cache}"
render_config_dir="${RENDER_CONFIG_DIR:-/tmp/render-flutter-config}"
api_base_url="${API_BASE_URL:-https://mdcat-backend.onrender.com}"
firebase_api_key="${FIREBASE_API_KEY:-}"
firebase_app_id="${FIREBASE_APP_ID:-}"
firebase_sender_id="${FIREBASE_MESSAGING_SENDER_ID:-}"
firebase_project_id="${FIREBASE_PROJECT_ID:-}"
firebase_storage_bucket="${FIREBASE_STORAGE_BUCKET:-}"
firebase_vapid_key="${FIREBASE_WEB_VAPID_KEY:-}"

if [[ ! -x "$render_flutter_dir/bin/flutter" ]]; then
  git clone --depth 1 --branch stable \
    https://github.com/flutter/flutter.git "$render_flutter_dir"
fi

export PUB_CACHE="$render_pub_cache"
export XDG_CONFIG_HOME="$render_config_dir"
export FLUTTER_SUPPRESS_ANALYTICS=true
mkdir -p "$PUB_CACHE" "$XDG_CONFIG_HOME"

"$render_flutter_dir/bin/flutter" config --enable-web
pushd mdcat_app >/dev/null
"$render_flutter_dir/bin/flutter" pub get
"$render_flutter_dir/bin/flutter" build web --release \
  --base-href "/" \
  --dart-define="API_BASE_URL=$api_base_url" \
  --dart-define="FIREBASE_API_KEY=$firebase_api_key" \
  --dart-define="FIREBASE_APP_ID=$firebase_app_id" \
  --dart-define="FIREBASE_MESSAGING_SENDER_ID=$firebase_sender_id" \
  --dart-define="FIREBASE_PROJECT_ID=$firebase_project_id" \
  --dart-define="FIREBASE_STORAGE_BUCKET=$firebase_storage_bucket" \
  --dart-define="FIREBASE_WEB_VAPID_KEY=$firebase_vapid_key"
popd >/dev/null
