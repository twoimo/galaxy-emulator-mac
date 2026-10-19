---
name: "galaxy-control"
description: "Unified control for Samsung Galaxy (Tailscale wireless ADB) and Apple Silicon ARM64 Android Virtual Devices (emulator-5554). Supports auto-connect, UI observation (uidump/screenshot), and LLM touch/key automation."
---

# Galaxy & Android Unified Control (Agent Specification)

This skill consolidates **wireless Tailscale ADB connectivity**, **local Apple Silicon ARM64 AVD emulation**, and **deterministic LLM touch automation** into one unified command interface (`galaxy-emu`).

---

## 🧭 Target Architecture & Routing

| Device Target | Identifier | Typical Role | Access & Control |
|---|---|---|---|
| **Virtual AVD Machine** | `emulator-5554` | Testing, disposable runs, CI/CD | `galaxy-emu -s emulator-5554 <cmd>` |
| **Physical Galaxy Phone** | `100.109.128.97:39547` (or USB serial) | Real production data, KakaoTalk | `galaxy-emu -s <serial> <cmd>` |

### Auto-Routing Policy
- If `-s <serial>` is omitted, `galaxy-emu` **automatically selects the running emulator first**, and falls back to connected physical devices.
- For personal phone tasks, explicitly specify the physical serial.

---

## 🔌 1. Connectivity Layer (Tailscale Wireless ADB)

Replaces `remote-adb-tailscale` with a one-command workflow:

```bash
# Auto-detect active Galaxy in Tailnet and connect wireless ADB
galaxy-emu connect

# Connect explicit endpoint
galaxy-emu connect 100.109.128.97:5555

# List all active connections
galaxy-emu devices

# Disconnect wireless transport
galaxy-emu disconnect
```

---

## 💻 2. Virtual Machine Lifecycle (Local Apple Silicon AVD)

Runs with pure ARM64 Apple Silicon Hypervisor & Metal GPU hardware acceleration:

```bash
# Boot Galaxy S24 Ultra AVD and wait until sys.boot_completed=1
galaxy-emu boot s24u

# Headless boot for background agents
galaxy-emu boot s24u --headless

# Gracefully stop emulator
galaxy-emu stop emulator-5554
```

---

## 🔍 3. Observation Loop (UI Hierarchy & Vision)

Before taking any touch action, inspect what is on screen:

```bash
# A. Get currently focused foreground package and activity
galaxy-emu current

# B. Dump interactive UI elements with exact center tap coordinates
galaxy-emu uidump

# C. Machine-readable JSON output for automated coordinate lookup
galaxy-emu uidump --json

# D. High-res screen capture for visual validation
galaxy-emu screenshot /tmp/screen.png
```

---

## 👆 4. Action Execution (Touch, Keys, Typing)

```bash
# Tap exact coordinate (e.g. Center from uidump)
galaxy-emu tap 720 1560

# Swipe / scroll between coordinates
galaxy-emu swipe 720 2000 720 800 300

# Type text into focused input (spaces & special chars auto-escaped)
galaxy-emu type "Hello World"

# Hardware Key Events: HOME, BACK, POWER, ENTER, APP_SWITCH, VOL_UP, VOL_DOWN
galaxy-emu key HOME
galaxy-emu key BACK
galaxy-emu key ENTER

# Launch app component or open web URL
galaxy-emu app start "https://google.com"
galaxy-emu app start "com.android.chrome/com.google.android.apps.chrome.Main"

# Force stop package
galaxy-emu app stop "com.android.chrome"
```

---

## 🖥️ 5. Desktop Mirroring (`scrcpy`)

When the user wants to see and interact with their physical Galaxy phone on macOS:
```bash
# Launches 60fps low-latency window with phone display turned off (0mA power saving)
galaxy-emu mirror -s 100.109.128.97:39547
```
