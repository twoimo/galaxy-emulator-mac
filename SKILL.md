---
name: "galaxy-emulator"
description: "Control, mirror, and automate Samsung Galaxy devices (S24 Ultra, Z Flip5) and Apple Silicon ARM64 Android emulators via CLI, scrcpy, and tapflow."
---

# Galaxy Emulator & Device Control (Apple Silicon Native)

This skill provides unified control for both **physical Samsung Galaxy devices (S24 Ultra, Z Flip5 via wireless ADB/Tailscale)** and **Apple Silicon native ARM64 Android Virtual Devices (AVD)**, along with **scrcpy desktop mirroring** and **tapflow browser streaming**.

Compatible with **Aside Browser**, **Local ChatGPT / Codex Desktop App**, and **Grok Bot**.

---

## 🧭 Capabilities & Mode Matrix

| Mode | Target | Toolchain | Primary Use Case |
|---|---|---|---|
| **1. Physical Galaxy Mirroring** | Real S24 Ultra / Z Flip5 | `scrcpy` + `adb` (Tailscale) | Access real apps, Knox, banking, One UI with phone screen off |
| **2. Standalone ARM64 AVD** | Virtual Galaxy S24U / Flip5 | `galaxy-emu` (QEMU/Hypervisor) | Isolated test environment, automated APK testing without real device |
| **3. Web Browser Streaming** | AVD or Physical Device | `tapflow` (WebRTC / H.264) | Interact with Android inside an Aside or Chrome browser tab |

---

## 🛠️ Prerequisites & Paths

On Apple Silicon Mac:
- **ADB & scrcpy**: `/opt/homebrew/bin/adb`, `/opt/homebrew/bin/scrcpy`
- **CLI Tool**: `~/Documents/projects/galaxy-emulator-mac/bin/galaxy-emu`
- **Tapflow Repo**: `~/Documents/projects/tapflow`

Ensure PATH includes Homebrew:
```bash
export PATH="/opt/homebrew/bin:$PATH"
```

---

## 📱 Mode 1: Physical Galaxy Wireless Mirroring & Control

Use when the user wants to view or operate their real Galaxy phone on macOS.

### 1. Check Connected Devices
```bash
export PATH="/opt/homebrew/bin:$PATH"
adb devices -l
```
*Identifies real device (e.g. `SM_S928N` for S24 Ultra over Tailscale or USB).*

### 2. Launch Screen-Off Desktop Window
Keeps the phone display completely dark to prevent battery drain while controlling from Mac:
```bash
# Launch with window title, keep awake, turn phone screen off
scrcpy -s <SERIAL> \
  --turn-screen-off \
  --stay-awake \
  --window-title "Galaxy S24 Ultra" \
  --always-on-top
```

### 3. Non-interactive Inspection & Capture (Agent Automation)
Agents can take screenshots or inspect UI hierarchy without GUI windows:
```bash
# Capture screenshot to local file
adb -s <SERIAL> exec-out screencap -p > /tmp/galaxy-screen.png

# Send text input
adb -s <SERIAL> shell input text "hello"

# Send key event (Home: 3, Back: 4, Power: 26)
adb -s <SERIAL> shell input keyevent 3
```

---

## 💻 Mode 2: Standalone ARM64 Virtual Galaxy (AVD)

Use when an isolated, disposable Android environment is required.

### 1. Inspect Status
```bash
~/Documents/projects/galaxy-emulator-mac/bin/galaxy-emu doctor
~/Documents/projects/galaxy-emulator-mac/bin/galaxy-emu list
```

### 2. Create Galaxy Profile AVD
- **`s24u`**: Galaxy S24 Ultra (1440 × 3120, 505 dpi, 8GB RAM, 6 vCPU, Android 14)
- **`flip5`**: Galaxy Z Flip5 (1080 × 2640, 425 dpi, 6GB RAM, 4 vCPU, Android 14)

```bash
~/Documents/projects/galaxy-emulator-mac/bin/galaxy-emu create s24u
```

### 3. Launch Standalone Phone Window
Runs with macOS `Hypervisor.framework` ARM64 hardware acceleration and Metal Host GPU:
```bash
# Normal standalone window
~/Documents/projects/galaxy-emulator-mac/bin/galaxy-emu run s24u

# Cold boot (bypass snapshot)
~/Documents/projects/galaxy-emulator-mac/bin/galaxy-emu run s24u --cold

# Headless mode (for background CI/automation agents)
~/Documents/projects/galaxy-emulator-mac/bin/galaxy-emu run s24u --headless
```

---

## 🌐 Mode 3: Web Browser Streaming via Tapflow

Use when the user wants the phone view embedded directly into a browser tab.

```bash
cd ~/Documents/projects/tapflow
./scripts/galaxy-stream.sh
```
Then navigate to `http://localhost:3000` in Aside Browser or Chrome.

---

## 🤖 Agent Execution Rules

1. **Check ADB device first**: Run `adb devices -l`. If an active Galaxy (e.g. `SM_S928N`) is already connected via Tailscale, ask or prefer Mode 1 for real-phone access.
2. **Never wake phone display unnecessarily**: Always pass `--turn-screen-off` when launching scrcpy to respect user privacy and battery life.
3. **Keep AVD lightweight**: Use `--headless` when executing automated scripts or background tests so no disruptive window steals focus.
4. **Fast visual feedback**: Use `adb exec-out screencap -p` to verify state after touch or text injection.
