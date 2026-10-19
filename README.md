# 🌌 Galaxy Emulator for Mac (Apple Silicon Native)

> **Run optimized Samsung Galaxy ARM64 Android emulators on Apple Silicon Mac with a single lightweight CLI command — without opening the heavy Android Studio IDE.**

[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%20%7C%20M2%20%7C%20M3%20%7C%20M4%20%7C%20M5-blue.svg)](https://apple.com)
[![Architecture](https://img.shields.io/badge/Architecture-ARM64%20(Native)-success.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🎯 Background & Feasibility

### Why not a direct 1:1 ROM dump of a physical Galaxy?
A physical Samsung Galaxy phone cannot be cloned 1:1 into an emulator image due to:
1. **Knox Hardware Security & FBE (File-Based Encryption)**: Keystore tokens and biometric data are cryptographically bound to physical Knox Vault/TEE silicon.
2. **One UI & Proprietary HAL Drivers**: Samsung's firmware expects proprietary Qualcomm/Exynos hardware interfaces rather than hypervisor virtual devices.
3. **Integrity & Attestation**: Google Play Integrity checks flag emulators and unlocked bootloaders.

### The Solution: Optimized AVD Profile with Native ARM64 Acceleration
Instead of heavy x86 emulation or bulky IDE windows, `galaxy-emulator-mac` provisions a **pure ARM64 AVD tuned with exact Samsung Galaxy dimensions, pixel density, RAM sizing, and Metal-accelerated host rendering** directly on macOS `Hypervisor.framework`.

---

## 📱 Supported Galaxy Device Profiles

| Profile ID | Target Device | Resolution | Density | Tuned RAM | API Level |
|---|---|---|---|---|---|
| **`s24u`** | Samsung Galaxy S24 Ultra | 1440 × 3120 | 505 dpi | 8,192 MB (6 vCPU) | Android 14 (API 34) |
| **`flip5`** | Samsung Galaxy Z Flip5 | 1080 × 2640 | 425 dpi | 6,144 MB (4 vCPU) | Android 14 (API 34) |

---

## 🚀 Quick Start

### 1. Requirements
- macOS with Apple Silicon (M1/M2/M3/M4/M5 series)
- Android SDK command-line tools (`cmdline-tools`, `emulator`, `platform-tools`)
  ```bash
  brew install --cask android-commandlinetools
  brew install android-platform-tools
  ```

### 2. Setup SDK & ARM64 Images
Run the environment setup script to accept licenses and install the ARM64 Google Play system image:
```bash
./bin/galaxy-emu setup
```

### 3. Create Galaxy AVD
Generate and tune the device configuration:
```bash
# Create Galaxy S24 Ultra
./bin/galaxy-emu create s24u

# Or Galaxy Z Flip5
./bin/galaxy-emu create flip5
```

### 4. Run the Emulator
Launch the standalone phone window with zero IDE overhead:
```bash
# Normal launch (uses fast snapshot boot)
./bin/galaxy-emu run s24u

# Cold boot without loading previous snapshots
./bin/galaxy-emu run s24u --cold

# Headless mode for background automation / ADB agents
./bin/galaxy-emu run s24u --headless
```

---

## 🛠️ CLI Reference

```text
Usage: galaxy-emu <command> [options]

Commands:
  setup              Install or verify Android SDK, cmdline-tools, emulator, and ARM64 image
  create <profile>   Create and tune an AVD (profiles: s24u, flip5)
  run <profile>      Launch standalone emulator window (options: --cold, --headless)
  list               List available profiles and existing AVDs
  doctor             Check Apple Silicon environment, Hypervisor support, and SDK paths
  install <apk>      Install APK to currently running emulator instance via adb
  help               Show this help message
```

---

## ⚡ Apple Silicon Optimization Highlights

- **Native Hypervisor Pass-through**: ARM64 Android instructions execute directly on Apple M-series cores without translation overhead.
- **Metal Host GPU Acceleration**: `-gpu host` utilizes macOS Metal graphics API for 60~120 FPS UI smoothness.
- **Standalone Process**: No Gradle daemon, no Kotlin indexing, no Electron wrapper. Only the isolated phone frame window is rendered.
- **Webcam Passthrough**: Built-in Mac FaceTime HD camera acts as the rear/front camera (`webcam0`).

---

## 📄 License

MIT License. Created by [twoimo (Yeonwoo Choi)](https://github.com/twoimo).


---

## Performance tuning (measured)

Applied after checking [kdbhalala/avdslim](https://github.com/kdbhalala/avdslim) recommendations.
Their headline claim (8.5 GB -> 2.5 GB) mostly targets setups where `hw.gpu.mode=auto` falls back to
Mesa software rasterization; this profile already pins `hw.gpu.mode=host`, so most of that win was
already banked.

| Change | Why |
|---|---|
| `hw.camera.back/front = none` | webcam capture threads are pure overhead for agent work |
| `hw.audioInput = no` | mic input unused; audio output stays for video |
| `hw.ramSize 8192 -> 4096` | 3.8 GB is enough for Instagram + Chrome, 1.7 GB still free |
| `hw.cpu.ncore 6 -> 8` | host has 18 cores |
| launch flags `-no-boot-anim -netdelay none -netspeed full` | faster, more realistic boot |

Measured on Apple M5 Max (`Galaxy_S24_Ultra`, Android 14, 1440x3120 @505dpi):

| Metric | Before | After |
|---|---|---|
| Cold boot to `sys.boot_completed=1` | 20 s | **16 s** |
| Guest RAM (`MemTotal`) | 8.0 GB | 3.8 GB |
| Host RSS, idle just after boot | 6.4 GB | 6.4 GB (unchanged) |
| Host RSS, Instagram + Chrome loaded | up to 10.6 GB | 6.8 GB |
| OOM / lmkd kills with both apps | - | none |

Host RSS at idle did not drop: with host GPU already enabled, the footprint is dominated by the
guest image and Metal buffers, not by a software rasterizer. Reducing guest RAM mainly lowers guest
memory pressure and GC churn.

Restore the previous AVD config with:

```bash
cp ~/.android/avd/Galaxy_S24_Ultra.avd/config.ini.bak.<timestamp> \
   ~/.android/avd/Galaxy_S24_Ultra.avd/config.ini
```

### Not adopted

- `-lowram` / 1536 MB guest RAM: too tight for Instagram-class apps; avdslim itself recommends it for CI.
- Third-party emulator builds (`NKS1608/kiln-android-emulator`, `Ccccccccvvm/qemu-android-arm64`): hobby
  rewrites of QEMU/HVF. Using them would break Play Store, Play Integrity and this toolchain's assumptions.
- `741g/android-emulator-m1-preview`: deprecated by its own README in favour of Google's official emulator.
- Docker solutions (`budtmo/docker-android` 16k★, `HQarroum/docker-android` 7.3k★, `Shmayro/dockerify-android`):
  Linux-host only; they need a Linux VM on macOS, which adds a layer instead of removing one.
