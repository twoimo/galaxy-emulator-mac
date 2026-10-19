#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-s24u}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PROFILE_FILE="$ROOT_DIR/profiles/${PROFILE}.json"

if [ ! -f "$PROFILE_FILE" ]; then
  echo "❌ Unknown profile: $PROFILE. Available: s24u, flip5"
  exit 1
fi

NAME=$(node -e "console.log(require('$PROFILE_FILE').name)")
DISPLAY_NAME=$(node -e "console.log(require('$PROFILE_FILE').displayName)")

SDK_PATH="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
EMULATOR=""
for cand in \
  "$SDK_PATH/emulator/emulator" \
  /opt/homebrew/bin/emulator \
  "$(which emulator 2>/dev/null || true)"; do
  if [ -n "$cand" ] && [ -x "$cand" ]; then
    EMULATOR="$cand"
    break
  fi
done

if [ -z "$EMULATOR" ]; then
  echo "❌ 'emulator' binary not found. Please run ./scripts/setup.sh"
  exit 1
fi

shift 1 || true
EXTRA_ARGS=("$@")

echo "📱 Launching $DISPLAY_NAME ($NAME)..."
echo "⚡ Native Apple Silicon ARM64 acceleration with Metal Host GPU."

# Options tuned for maximum responsiveness on Apple Silicon
"$EMULATOR" \
  -avd "$NAME" \
  -gpu host \
  -camera-back webcam0 \
  -camera-front webcam0 \
  -no-boot-anim \
  -no-audio \
  "${EXTRA_ARGS[@]}"
