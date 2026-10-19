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

1. **Mandatory Visual Presentation (Aside Sessions)**:
   - When the user asks about phone state, mirroring, emulator runs, or general device inspection in Aside, **ALWAYS accompany your reply with the interactive `visual` Card**.
   - Gather live telemetry using:
     - Focus app: `adb shell "dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'"`
     - Battery & temp: `adb shell dumpsys battery | grep -E 'level|temperature'`
     - Display state: `adb shell dumpsys power | grep mWakefulness`
     - Memory: `adb shell "cat /proc/meminfo | grep -E 'MemTotal|MemAvailable'"`
     - Recent logcat: `adb shell "logcat -d -t 15 --format=time"`
   - Render the complete `visual` HTML block with:
     - Left: Smartphone Mockup (punch-hole, status bar, app badge, network status, nav bar)
     - Top Right: Metrics grid (Battery, Display, Resolution, Network) & LPDDR5X Memory progress bar
     - Mid Right: Action buttons (`scrcpy` standalone, `tapflow` browser tab)
     - Bottom Right: Real-time dark Logcat console window with log level tags + Quick Remote Keypad (Home, Back, Power, Screencap).
2. **Check ADB device first**: Run `adb devices -l`. If an active Galaxy (e.g. `SM_S928N`) is already connected via Tailscale, ask or prefer Mode 1 for real-phone access.
3. **Never wake phone display unnecessarily**: Always pass `--turn-screen-off` when launching scrcpy to respect user privacy and battery life.
4. **Keep AVD lightweight**: Use `--headless` when executing automated scripts or background tests so no disruptive window steals focus.
5. **Fast visual feedback**: Use `adb exec-out screencap -p` to verify state after touch or text injection.

---

## 🎨 Visual Card HTML Template Reference

When emitting the visual card in Aside, use this exact structure in a \`\`\`visual code block:

\`\`\`html
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Galaxy S24 Ultra Live Telemetry & Logcat</title>
  <style>
    :root { --phone-w: 260px; --phone-h: 585px; }
    body { margin: 0; padding: 12px 0; font-family: var(--font-sans, system-ui); color: var(--foreground); display: flex; justify-content: center; background: transparent; }
    .container { display: flex; flex-wrap: wrap; gap: 20px; align-items: stretch; max-width: 760px; width: 100%; }
    .phone-mockup { width: var(--phone-w); height: var(--phone-h); background: var(--surface-primary, #1e1e1e); border-radius: 36px; border: 3.5px solid var(--border, #333); box-shadow: 0 12px 32px rgba(0,0,0,0.2); position: relative; display: flex; flex-direction: column; overflow: hidden; flex-shrink: 0; }
    .camera-hole { position: absolute; top: 10px; left: 50%; transform: translateX(-50%); width: 10px; height: 10px; background: #000; border-radius: 50%; z-index: 10; }
    .status-bar { height: 26px; padding: 6px 14px 0; display: flex; justify-content: space-between; font-size: 10px; font-weight: 600; color: var(--muted-foreground); font-variant-numeric: tabular-nums; z-index: 5; }
    .screen-content { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 16px; text-align: center; background: linear-gradient(180deg, rgba(0,0,0,0.02) 0%, rgba(0,0,0,0.18) 100%); }
    .app-icon-badge { width: 52px; height: 52px; background: #fae100; border-radius: 14px; display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 18px; color: #371d1e; margin-bottom: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.12); }
    .app-title { font-size: 14px; font-weight: 600; margin-bottom: 2px; }
    .app-sub { font-size: 11px; color: var(--muted-foreground); margin-bottom: 14px; }
    .state-pill { display: inline-flex; align-items: center; gap: 6px; background: color-mix(in oklab, var(--chart-1) 15%, transparent); color: var(--chart-1); padding: 3px 8px; border-radius: 16px; font-size: 10px; font-weight: 600; }
    .pulse-dot { width: 6px; height: 6px; background: var(--chart-1); border-radius: 50%; box-shadow: 0 0 6px var(--chart-1); }
    .nav-bar { height: 30px; display: flex; justify-content: space-around; align-items: center; font-size: 12px; color: var(--muted-foreground); padding-bottom: 2px; }
    .info-panel { flex: 1; min-width: 320px; display: flex; flex-direction: column; gap: 12px; height: var(--phone-h); box-sizing: border-box; }
    .panel-header { border-bottom: 1px solid var(--border); padding-bottom: 6px; display: flex; justify-content: space-between; align-items: flex-end; }
    .panel-title { font-size: 17px; font-weight: 600; letter-spacing: -0.02em; }
    .panel-sub { font-size: 11px; color: var(--muted-foreground); }
    .chip-live { font-size: 10px; font-weight: 700; color: var(--success, #10b981); background: color-mix(in oklab, var(--success, #10b981) 15%, transparent); padding: 2px 6px; border-radius: 4px; }
    .data-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }
    .data-box { background: var(--surface-primary); border: 1px solid var(--border); border-radius: var(--radius, 6px); padding: 6px 8px; }
    .data-label { font-size: 10px; color: var(--muted-foreground); margin-bottom: 2px; }
    .data-value { font-size: 12px; font-weight: 600; font-variant-numeric: tabular-nums; }
    .mem-row { display: flex; flex-direction: column; gap: 4px; background: var(--surface-primary); border: 1px solid var(--border); border-radius: var(--radius, 6px); padding: 8px 10px; }
    .mem-header { display: flex; justify-content: space-between; font-size: 11px; font-weight: 500; }
    .mem-header span:last-child { color: var(--muted-foreground); font-variant-numeric: tabular-nums; }
    .progress-track { width: 100%; height: 6px; background: var(--muted); border-radius: 3px; overflow: hidden; }
    .progress-fill { height: 100%; background: var(--chart-1); border-radius: 3px; }
    .actions-box { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
    .btn { display: flex; align-items: center; justify-content: center; gap: 6px; padding: 7px 10px; border-radius: var(--radius, 6px); font-size: 11px; font-weight: 500; border: 1px solid var(--border); background: var(--surface-primary); color: var(--foreground); cursor: pointer; text-decoration: none; }
    .btn:hover { background: var(--muted); }
    .btn-primary { background: var(--primary); color: var(--primary-foreground); border-color: var(--primary); }
    .console-card { flex: 1; background: #0f1115; color: #cbd5e1; border: 1px solid var(--border); border-radius: var(--radius, 8px); display: flex; flex-direction: column; overflow: hidden; min-height: 180px; }
    .console-header { background: #181b21; padding: 6px 10px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid rgba(255,255,255,0.08); font-size: 11px; font-family: var(--font-mono, monospace); }
    .mac-dots { display: flex; gap: 5px; }
    .mac-dot { width: 8px; height: 8px; border-radius: 50%; }
    .dot-r { background: #ff5f56; } .dot-y { background: #ffbd2e; } .dot-g { background: #27c93f; }
    .console-title { font-size: 10px; color: #94a3b8; }
    .console-body { flex: 1; padding: 8px 10px; font-family: var(--font-mono, monospace); font-size: 10px; line-height: 1.5; overflow-y: auto; white-space: pre-wrap; word-break: break-all; }
    .log-line { display: block; margin-bottom: 2px; }
    .log-time { color: #64748b; margin-right: 6px; }
    .log-info { color: #38bdf8; }
    .log-warn { color: #facc15; }
    .log-err  { color: #f87171; }
    .log-adbd { color: #4ade80; }
    .log-tag  { color: #a78bfa; margin-right: 6px; }
    .quick-keys { display: flex; gap: 6px; padding: 4px 8px; background: #181b21; border-top: 1px solid rgba(255,255,255,0.08); }
    .key-btn { flex: 1; background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.1); color: #94a3b8; border-radius: 4px; font-size: 10px; padding: 3px 0; text-align: center; cursor: pointer; }
    .key-btn:hover { background: rgba(255,255,255,0.12); color: #fff; }
  </style>
</head>
<body>
  <!-- Container with mockup + telemetry + logcat -->
</body>
</html>
\`\`\`
