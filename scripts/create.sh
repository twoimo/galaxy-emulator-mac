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

SDK_PATH="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
AVDMANAGER=""
for cand in \
  "$SDK_PATH/cmdline-tools/latest/bin/avdmanager" \
  "$SDK_PATH/cmdline-tools/bin/avdmanager" \
  /opt/homebrew/bin/avdmanager \
  "$(which avdmanager 2>/dev/null || true)"; do
  if [ -n "$cand" ] && [ -x "$cand" ]; then
    AVDMANAGER="$cand"
    break
  fi
done

if [ -z "$AVDMANAGER" ]; then
  echo "❌ 'avdmanager' not found. Please run ./scripts/setup.sh first."
  exit 1
fi

# Parse profile JSON using node
NAME=$(node -e "console.log(require('$PROFILE_FILE').name)")
DISPLAY_NAME=$(node -e "console.log(require('$PROFILE_FILE').displayName)")
WIDTH=$(node -e "console.log(require('$PROFILE_FILE').width)")
HEIGHT=$(node -e "console.log(require('$PROFILE_FILE').height)")
DENSITY=$(node -e "console.log(require('$PROFILE_FILE').density)")
RAM=$(node -e "console.log(require('$PROFILE_FILE').ramMb)")
HEAP=$(node -e "console.log(require('$PROFILE_FILE').heapMb)")
CORES=$(node -e "console.log(require('$PROFILE_FILE').cores)")
SYS_IMAGE=$(node -e "console.log(require('$PROFILE_FILE').systemImage)")
TAG=$(node -e "console.log(require('$PROFILE_FILE').tag)")
ABI=$(node -e "console.log(require('$PROFILE_FILE').abi)")

echo "🚀 Creating AVD: $DISPLAY_NAME ($NAME)..."
echo "   Resolution: ${WIDTH}x${HEIGHT} (${DENSITY} dpi)"
echo "   RAM: ${RAM} MB, Cores: ${CORES}"
echo "   System Image: $SYS_IMAGE"

# Create AVD
echo "no" | "$AVDMANAGER" create avd \
  -n "$NAME" \
  -k "$SYS_IMAGE" \
  --tag "$TAG" \
  --abi "$ABI" \
  --force

AVD_DIR="$HOME/.android/avd/${NAME}.avd"
CONFIG_FILE="$AVD_DIR/config.ini"

if [ -f "$CONFIG_FILE" ]; then
  echo "⚙️ Tuning $CONFIG_FILE for Samsung Galaxy spec & Apple Silicon..."
  
  # Remove conflicting keys
  grep -v -E "(hw.lcd.width|hw.lcd.height|hw.lcd.density|hw.ramSize|vm.heapSize|hw.cpu.ncore|hw.gpu.enabled|hw.gpu.mode|hw.keyboard|hw.mainKeys|fastboot.forceFastBoot|hw.arc|hw.camera.back)" \
    "$CONFIG_FILE" > "$CONFIG_FILE.tmp" || true

  # Optional slim profile keys (camera/audio are pure overhead for agent use)
  CAM_BACK=$(node -e "console.log(require('$PROFILE_FILE').cameraBack || 'webcam0')" 2>/dev/null || echo webcam0)
  CAM_FRONT=$(node -e "console.log(require('$PROFILE_FILE').cameraFront || 'webcam0')" 2>/dev/null || echo webcam0)
  AUD_IN=$(node -e "console.log(require('$PROFILE_FILE').audioInput || 'yes')" 2>/dev/null || echo yes)

  cat <<EOF >> "$CONFIG_FILE.tmp"
hw.lcd.width = $WIDTH
hw.lcd.height = $HEIGHT
hw.lcd.density = $DENSITY
hw.ramSize = $RAM
vm.heapSize = $HEAP
hw.cpu.ncore = $CORES
hw.gpu.enabled = yes
hw.gpu.mode = host
hw.keyboard = yes
hw.mainKeys = no
hw.camera.back = $CAM_BACK
hw.camera.front = $CAM_FRONT
hw.audioInput = $AUD_IN
fastboot.forceFastBoot = yes
tag.display = $DISPLAY_NAME
EOF

  mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  echo "✅ Configuration successfully updated!"
else
  echo "⚠️ Warning: Config file not found at $CONFIG_FILE"
fi

echo ""
echo "🎉 Device $NAME is ready!"
echo "Run it now with: ./scripts/run.sh $PROFILE"
