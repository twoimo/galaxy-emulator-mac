#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " [galaxy-emulator-mac] Environment & SDK Setup Check"
echo "=========================================================="

# Check architecture
ARCH=$(uname -m)
if [ "$ARCH" != "arm64" ]; then
  echo "⚠️ Warning: This tool is tuned for Apple Silicon (arm64). Current: $ARCH"
fi

# Detect ANDROID_HOME / ANDROID_SDK_ROOT
SDK_PATH="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
export ANDROID_HOME="$SDK_PATH"
export ANDROID_SDK_ROOT="$SDK_PATH"

echo "📍 Target Android SDK Location: $ANDROID_HOME"

if [ ! -d "$ANDROID_HOME/cmdline-tools" ]; then
  echo "📦 cmdline-tools not found. Installing via Homebrew or directory check..."
  if command -v brew >/dev/null 2>&1; then
    echo "💡 Homebrew detected. Ensuring android-platform-tools is installed..."
    brew install --quiet android-platform-tools || true
  fi
  echo ""
  echo "👉 If you do not have Android Studio installed, you can install the standalone SDK tools:"
  echo "   brew install --cask android-commandlinetools"
  echo "   or install Android Studio via: brew install --cask android-studio"
fi

# Locate sdkmanager and avdmanager
SDKMANAGER=""
for cand in \
  "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
  "$ANDROID_HOME/cmdline-tools/bin/sdkmanager" \
  /opt/homebrew/bin/sdkmanager \
  "$(which sdkmanager 2>/dev/null || true)"; do
  if [ -n "$cand" ] && [ -x "$cand" ]; then
    SDKMANAGER="$cand"
    break
  fi
done

if [ -z "$SDKMANAGER" ]; then
  echo "❌ 'sdkmanager' not found in PATH or standard SDK locations."
  echo "Please install Android command-line tools or set ANDROID_HOME properly."
  echo "Example:"
  echo "  brew install --cask android-commandlinetools"
  exit 1
fi

echo "✅ Found sdkmanager at: $SDKMANAGER"

echo "📥 Accepting licenses..."
yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true

IMAGE_TARGET="system-images;android-34;google_apis_playstore;arm64-v8a"
echo "📥 Checking required ARM64 system image ($IMAGE_TARGET)..."
"$SDKMANAGER" --install "platform-tools" "emulator" "$IMAGE_TARGET"

echo ""
echo "🎉 Setup complete! You can now create your Galaxy devices with:"
echo "   ./scripts/create.sh s24u"
echo "   ./scripts/create.sh flip5"
