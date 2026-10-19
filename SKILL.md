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
  <title>Galaxy S24 Ultra - Virtual AVD & Physical Device Switcher</title>
  <style>
    :root {
      --phone-w: 260px;
      --phone-h: 585px;
    }
    body {
      margin: 0;
      padding: 12px 0;
      font-family: var(--font-sans, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto);
      color: var(--foreground);
      display: flex;
      justify-content: center;
      background: transparent;
    }
    .container {
      display: flex;
      flex-wrap: wrap;
      gap: 20px;
      align-items: stretch;
      max-width: 760px;
      width: 100%;
    }
    .phone-mockup {
      width: var(--phone-w);
      height: var(--phone-h);
      background: #050b14;
      border-radius: 36px;
      border: 3.5px solid var(--border);
      box-shadow: 0 10px 25px rgba(0,0,0,0.12);
      position: relative;
      display: flex;
      flex-direction: column;
      overflow: hidden;
      flex-shrink: 0;
      box-sizing: border-box;
      color: #fff;
    }
    .camera-hole {
      position: absolute;
      top: 10px;
      left: 50%;
      transform: translateX(-50%);
      width: 10px;
      height: 10px;
      background: #000;
      border-radius: 50%;
      z-index: 20;
      box-shadow: 0 0 2px rgba(255,255,255,0.25);
    }
    .status-bar {
      height: 24px;
      padding: 6px 14px 0;
      display: flex;
      justify-content: space-between;
      font-size: 10px;
      font-weight: 600;
      color: rgba(255,255,255,0.85);
      font-variant-numeric: tabular-nums;
      z-index: 15;
    }
    .screen-content {
      flex: 1;
      width: 100%;
      height: 100%;
      position: relative;
      background: radial-gradient(circle at 50% 30%, #1e293b 0%, #090d16 100%);
      display: flex;
      flex-direction: column;
      padding: 10px 14px;
      box-sizing: border-box;
      justify-content: space-between;
    }
    .mode-badge {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      background: rgba(0,0,0,0.6);
      backdrop-filter: blur(8px);
      border: 1px solid rgba(255,255,255,0.15);
      border-radius: 20px;
      padding: 2px 8px;
      font-size: 9px;
      font-weight: 700;
      color: #38bdf8;
      align-self: flex-start;
      margin-bottom: 8px;
    }
    .pulse-dot {
      width: 5px;
      height: 5px;
      background: #38bdf8;
      border-radius: 50%;
      box-shadow: 0 0 6px #38bdf8;
      animation: pulse 2s infinite ease-in-out;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.4; transform: scale(0.85); }
    }
    .clock-widget { text-align: center; margin: 8px 0 14px; }
    .clock-time { font-size: 40px; font-weight: 300; letter-spacing: -0.04em; line-height: 1; color: #f8fafc; font-variant-numeric: tabular-nums; }
    .clock-date { font-size: 11px; color: #94a3b8; margin-top: 4px; }
    .search-bar { background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.12); border-radius: 24px; padding: 6px 12px; display: flex; align-items: center; justify-content: space-between; font-size: 11px; color: #cbd5e1; margin-bottom: 16px; backdrop-filter: blur(10px); }
    .app-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px 6px; text-align: center; }
    .app-item { display: flex; flex-direction: column; align-items: center; gap: 4px; cursor: pointer; user-select: none; transition: transform 0.1s; }
    .app-item:hover { transform: scale(1.06); }
    .app-icon { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 17px; box-shadow: 0 4px 8px rgba(0,0,0,0.3); }
    .app-label { font-size: 9px; color: #e2e8f0; max-width: 46px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .bg-play { background: linear-gradient(135deg, #00c9ff, #92fe9d); color: #0f172a; }
    .bg-chrome { background: linear-gradient(135deg, #ea4335, #fbbc05, #34a853, #4285f4); color: #fff; }
    .bg-maps { background: linear-gradient(135deg, #34a853, #4285f4); color: #fff; }
    .bg-yt { background: #ff0000; color: #fff; }
    .bg-settings { background: #475569; color: #f8fafc; }
    .bg-photos { background: linear-gradient(135deg, #ff758c, #ff7eb3); color: #fff; }
    .bg-files { background: #0284c7; color: #fff; }
    .bg-terminal { background: #1e293b; border: 1px solid #475569; color: #38bdf8; font-family: var(--font-mono); font-weight: 700; font-size: 13px; }
    .bg-phone { background: #22c55e; color: #fff; }
    .bg-msg { background: #3b82f6; color: #fff; }
    .bg-camera { background: #0f172a; border: 1px solid #334155; color: #fff; }
    .bg-galaxy { background: linear-gradient(135deg, #6366f1, #a855f7); color: #fff; font-weight: 800; }
    .dock-area { background: rgba(255,255,255,0.08); border-radius: 18px; padding: 8px 6px; display: grid; grid-template-columns: repeat(4, 1fr); gap: 6px; backdrop-filter: blur(12px); margin-top: auto; }
    .screen-toast { position: absolute; bottom: 60px; left: 50%; transform: translateX(-50%) translateY(8px); background: rgba(15,23,42,0.95); border: 1px solid rgba(255,255,255,0.2); color: #fff; padding: 5px 12px; border-radius: 20px; font-size: 10px; opacity: 0; transition: all 0.25s ease; pointer-events: none; z-index: 30; white-space: nowrap; }
    .screen-toast.show { opacity: 1; transform: translateX(-50%) translateY(0); }
    .nav-bar { height: 22px; display: flex; justify-content: center; align-items: center; background: #050b14; }
    .gesture-bar { width: 80px; height: 4px; background: rgba(255,255,255,0.6); border-radius: 2px; cursor: pointer; transition: background 0.15s; }
    .gesture-bar:hover { background: #fff; }
    /* OS Page Navigation */
    .os-page { display: none; width: 100%; height: 100%; flex-direction: column; box-sizing: border-box; }
    .os-page.active { display: flex; }
    /* YouTube View */
    .app-header-yt { display: flex; justify-content: space-between; align-items: center; padding: 4px 6px; font-weight: 700; font-size: 13px; color: #ff0000; border-bottom: 1px solid rgba(255,255,255,0.1); }
    .close-app { color: #94a3b8; cursor: pointer; font-size: 13px; padding: 2px 6px; border-radius: 4px; }
    .close-app:hover { color: #fff; background: rgba(255,255,255,0.1); }
    .yt-video-box { width: 100%; height: 130px; background: #000; border-radius: 8px; margin: 8px 0; display: flex; flex-direction: column; align-items: center; justify-content: center; position: relative; overflow: hidden; }
    .yt-play-btn { width: 36px; height: 36px; background: #ff0000; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; color: #fff; box-shadow: 0 4px 12px rgba(255,0,0,0.4); }
    .yt-title-bar { position: absolute; bottom: 6px; left: 8px; font-size: 9px; color: #e2e8f0; font-weight: 500; }
    .yt-feed { display: flex; flex-direction: column; gap: 8px; overflow-y: auto; flex: 1; padding-top: 4px; }
    .yt-card { display: flex; gap: 8px; align-items: center; background: rgba(255,255,255,0.05); padding: 6px; border-radius: 6px; }
    .yt-thumb { width: 50px; height: 32px; background: #334155; border-radius: 4px; flex-shrink: 0; }
    .yt-meta { flex: 1; overflow: hidden; }
    .yt-t1 { font-size: 9px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; color: #f8fafc; }
    .yt-t2 { font-size: 8px; color: #94a3b8; }
    /* Chrome View */
    .app-header-chrome { display: flex; justify-content: space-between; align-items: center; background: rgba(255,255,255,0.08); padding: 4px 10px; border-radius: 14px; font-size: 10px; color: #cbd5e1; }
    .chrome-body { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; }
    .chrome-search { background: rgba(255,255,255,0.1); border-radius: 20px; padding: 6px 14px; font-size: 10px; color: #94a3b8; width: 80%; }
    .info-panel { flex: 1; min-width: 320px; display: flex; flex-direction: column; gap: 12px; height: var(--phone-h); box-sizing: border-box; }
    .panel-header { border-bottom: 1px solid var(--border); padding-bottom: 6px; display: flex; justify-content: space-between; align-items: flex-end; }
    .panel-title { font-size: 17px; font-weight: 600; letter-spacing: -0.02em; }
    .panel-sub { font-size: 11px; color: var(--muted-foreground); }
    .device-tabs { display: flex; background: var(--muted); padding: 2px; border-radius: var(--radius); gap: 2px; }
    .dev-tab { flex: 1; text-align: center; padding: 5px 8px; font-size: 11px; font-weight: 600; border-radius: calc(var(--radius) - 2px); cursor: pointer; user-select: none; color: var(--muted-foreground); transition: all 0.15s; }
    .dev-tab.active { background: var(--surface-primary); color: var(--foreground); box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
    .data-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }
    .data-box { background: var(--surface-primary); border: 1px solid var(--border); border-radius: var(--radius); padding: 6px 8px; }
    .data-label { font-size: 10px; color: var(--muted-foreground); margin-bottom: 2px; }
    .data-value { font-size: 12px; font-weight: 600; font-variant-numeric: tabular-nums; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .spec-card { background: var(--surface-primary); border: 1px solid var(--border); border-radius: var(--radius); padding: 8px 10px; display: flex; flex-direction: column; gap: 4px; }
    .spec-row { display: flex; justify-content: space-between; font-size: 11px; }
    .spec-row span:first-child { color: var(--muted-foreground); }
    .spec-row span:last-child { font-weight: 600; font-variant-numeric: tabular-nums; }
    .actions-box { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
    .btn { display: flex; align-items: center; justify-content: center; gap: 6px; padding: 7px 10px; border-radius: var(--radius); font-size: 11px; font-weight: 500; border: 1px solid var(--border); background: var(--surface-primary); color: var(--foreground); cursor: pointer; text-decoration: none; transition: background 0.15s, transform 0.05s; user-select: none; box-sizing: border-box; }
    .btn:hover { background: var(--muted); }
    .btn-primary { background: var(--primary); color: var(--primary-foreground); border-color: var(--primary); }
    .console-card { flex: 1; background: var(--surface-secondary); color: var(--foreground); border: 1px solid var(--border); border-radius: var(--radius); display: flex; flex-direction: column; overflow: hidden; min-height: 160px; }
    .console-header { background: var(--muted); padding: 5px 10px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--border); font-size: 11px; font-family: var(--font-mono); }
    .mac-dots { display: flex; gap: 5px; }
    .mac-dot { width: 8px; height: 8px; border-radius: 50%; }
    .dot-r { background: var(--destructive); } .dot-y { background: var(--chart-4); } .dot-g { background: var(--success); }
    .console-title { font-size: 10px; color: var(--muted-foreground); }
    .console-body { flex: 1; padding: 8px 10px; font-family: var(--font-mono); font-size: 10px; line-height: 1.6; overflow-y: auto; overflow-x: auto; white-space: nowrap; scrollbar-width: thin; background: var(--surface-secondary); }
    .log-line { display: block; margin-bottom: 2px; white-space: nowrap; }
    .log-time { color: var(--muted-foreground); margin-right: 6px; }
    .log-info { color: var(--chart-1); font-weight: 600; margin-right: 4px; }
    .log-adbd { color: var(--success); font-weight: 600; margin-right: 4px; }
    .log-tag  { color: var(--chart-2); margin-right: 6px; }
    .quick-keys { display: flex; gap: 6px; padding: 4px 8px; background: var(--muted); border-top: 1px solid var(--border); }
    .key-btn { flex: 1; background: var(--surface-primary); border: 1px solid var(--border); color: var(--foreground); border-radius: 4px; font-size: 10px; padding: 3px 0; text-align: center; cursor: pointer; font-family: var(--font-sans); user-select: none; }
    .key-btn:hover { background: var(--accent); color: var(--accent-foreground); }
  </style>
</head>
<body>
  <div class="container">
    <div class="phone-mockup">
      <div class="camera-hole"></div>
      <div class="status-bar"><span>18:30</span><span>5G · 100% 🔋</span></div>
      <div class="screen-content" id="screenContent">
        <!-- Home Screen Page -->
        <div id="pageHome" class="os-page active">
          <div class="clock-widget"><div class="clock-time">18:30</div><div class="clock-date">Mon, Oct 19 · Seoul 21°C Clear</div></div>
          <div class="search-bar"><span>Search apps & web...</span><span>🎙️ 📷</span></div>
          <div class="app-grid">
            <div class="app-item" data-app="youtube"><div class="app-icon bg-yt">▶</div><span class="app-label">YouTube</span></div>
            <div class="app-item" data-app="chrome"><div class="app-icon bg-chrome">🌐</div><span class="app-label">Chrome</span></div>
            <div class="app-item" data-app="play"><div class="app-icon bg-play">▶</div><span class="app-label">Play Store</span></div>
            <div class="app-item" data-app="maps"><div class="app-icon bg-maps">📍</div><span class="app-label">Maps</span></div>
            <div class="app-item" data-app="photos"><div class="app-icon bg-photos">🖼️</div><span class="app-label">Photos</span></div>
            <div class="app-item" data-app="settings"><div class="app-icon bg-settings">⚙️</div><span class="app-label">Settings</span></div>
            <div class="app-item" data-app="files"><div class="app-icon bg-files">📁</div><span class="app-label">Files</span></div>
            <div class="app-item" data-app="term"><div class="app-icon bg-terminal">&gt;_</div><span class="app-label">ADB Term</span></div>
          </div>
          <div class="dock-area">
            <div class="app-item" data-app="phone"><div class="app-icon bg-phone">📞</div></div>
            <div class="app-item" data-app="msg"><div class="app-icon bg-msg">💬</div></div>
            <div class="app-item" data-app="chrome"><div class="app-icon bg-chrome">🌐</div></div>
            <div class="app-item" data-app="camera"><div class="app-icon bg-camera">📷</div></div>
          </div>
        </div>

        <!-- YouTube In-app Page -->
        <div id="pageYoutube" class="os-page">
          <div class="app-header-yt"><span>▶ YouTube</span><span id="btnCloseYt" class="close-app">✕</span></div>
          <div class="yt-video-box">
            <div class="yt-play-btn">▶</div>
            <div class="yt-title-bar">Android on Apple Silicon · M5 Max 120Hz Demo</div>
          </div>
          <div class="yt-feed">
            <div class="yt-card"><div class="yt-thumb"></div><div class="yt-meta"><div class="yt-t1">Samsung Galaxy S24 Ultra Long-term Review</div><div class="yt-t2">Android Central · 482K views</div></div></div>
            <div class="yt-card"><div class="yt-thumb"></div><div class="yt-meta"><div class="yt-t1">Building Agents with Aside & OpenCode</div><div class="yt-t2">Tech Lab · 120K views</div></div></div>
          </div>
        </div>

        <!-- Chrome In-app Page -->
        <div id="pageChrome" class="os-page">
          <div class="app-header-chrome"><span>google.com</span><span id="btnCloseChrome" class="close-app">✕</span></div>
          <div class="chrome-body">
            <div style="font-size: 26px; font-weight: 800; color: #4285f4; margin: 30px 0 10px;">Google</div>
            <div class="chrome-search">Search Google or type URL</div>
          </div>
        </div>

        <div id="phoneToast" class="screen-toast">App Launched</div>
      </div>
      <div class="nav-bar"><div class="gesture-bar" id="gestureHome" title="Swipe or click for Home"></div></div>
    </div>

    <div class="info-panel">
      <div class="device-tabs">
        <div id="tabAvd" class="dev-tab active">🤖 Android AVD Emulator</div>
        <div id="tabReal" class="dev-tab">📱 실물 Galaxy S24 Ultra</div>
      </div>
      <div class="panel-header">
        <div>
          <div class="panel-title" id="panelTitle">Galaxy S24 Ultra AVD</div>
          <div class="panel-sub" id="panelSub">Apple Silicon Native · Android 14 (API 34)</div>
        </div>
        <div class="chip-live" id="panelChip">● ARM64 NATIVE</div>
      </div>
      <div class="data-grid">
        <div class="data-box"><div class="data-label">Host Engine</div><div class="data-value" id="valHost">Hypervisor (M5)</div></div>
        <div class="data-box"><div class="data-label">GPU Mode</div><div class="data-value" id="valGpu">Metal (Host)</div></div>
        <div class="data-box"><div class="data-label">Resolution</div><div class="data-value">1440 × 3120</div></div>
        <div class="data-box"><div class="data-label">Pixel Density</div><div class="data-value">505 dpi</div></div>
      </div>
      <div class="spec-card">
        <div class="spec-row"><span>Target Architecture</span><span id="specArch">ARM64-v8a (Zero emulation overhead)</span></div>
        <div class="spec-row"><span>Allocated Memory</span><span id="specRam">8,192 MB (6 vCPU)</span></div>
        <div class="spec-row"><span>Relay / Streaming</span><span style="color: var(--success);" id="specRelay">Ready (tapflow port 3000)</span></div>
      </div>
      <div class="actions-box">
        <button id="btnLaunchEmu" class="btn btn-primary">⚡ AVD 단독 창 실행 (galaxy-emu)</button>
        <a id="btnTapflow" href="http://localhost:3000" target="_blank" class="btn">🌐 tapflow 웹 스트리밍 탭</a>
      </div>
      <div class="console-card">
        <div class="console-header">
          <div class="mac-dots"><span class="mac-dot dot-r"></span><span class="mac-dot dot-y"></span><span class="mac-dot dot-g"></span></div>
          <span class="console-title">Emulator Host Console & Logcat</span>
          <div class="console-tools"><span class="tag-filter active">ALL</span><span class="tag-filter">ADBD</span></div>
        </div>
        <div class="console-body" id="consoleBody">
          <span class="log-line"><span class="log-time">18:25:01.120</span><span class="log-info">[I]</span><span class="log-tag">emulator</span>Hypervisor.framework vCPU thread created: 6 cores</span>
          <span class="log-line"><span class="log-time">18:25:01.145</span><span class="log-info">[I]</span><span class="log-tag">renderer</span>Metal Host GPU pipeline initialized (1440x3120@120Hz)</span>
          <span class="log-line"><span class="log-time">18:25:01.210</span><span class="log-adbd">[I]</span><span class="log-tag">tapflow</span>Relay running on http://localhost:3000</span>
        </div>
        <div class="quick-keys">
          <div class="key-btn" data-key="Home">⌂ Home</div>
          <div class="key-btn" data-key="Back">↩ Back</div>
          <div class="key-btn" data-key="Power">⚡ Power</div>
          <div class="key-btn" data-key="Screencap">📸 Screencap</div>
        </div>
      </div>
    </div>
  </div>
  <script>
    function showToast(text) {
      const toast = document.getElementById('phoneToast');
      if (!toast) return;
      toast.textContent = text;
      toast.classList.add('show');
      setTimeout(() => toast.classList.remove('show'), 1500);
    }
    function appendLog(type, tag, msg) {
      const body = document.getElementById('consoleBody');
      if (!body) return;
      const time = new Date().toTimeString().split(' ')[0] + '.' + String(Date.now() % 1000).padStart(3, '0');
      const line = document.createElement('span');
      line.className = 'log-line';
      line.innerHTML = `<span class="log-time">${time}</span><span class="log-${type}">[${type.toUpperCase()}]</span><span class="log-tag">${tag}</span>${msg}`;
      body.appendChild(line);
      body.scrollTop = body.scrollHeight;
    }
    function showPage(pageId) {
      document.querySelectorAll('.os-page').forEach(p => p.classList.remove('active'));
      const target = document.getElementById(pageId);
      if (target) target.classList.add('active');
    }

    document.querySelectorAll('.app-item').forEach(item => {
      item.addEventListener('click', () => {
        const app = item.getAttribute('data-app');
        showToast('Launching ' + app.toUpperCase());
        appendLog('info', 'am_start', 'Intent: android.intent.action.MAIN (' + app + ')');
        if (app === 'youtube') showPage('pageYoutube');
        else if (app === 'chrome') showPage('pageChrome');
      });
    });

    const btnCloseYt = document.getElementById('btnCloseYt');
    if (btnCloseYt) btnCloseYt.addEventListener('click', () => showPage('pageHome'));

    const btnCloseChrome = document.getElementById('btnCloseChrome');
    if (btnCloseChrome) btnCloseChrome.addEventListener('click', () => showPage('pageHome'));

    const gestureHome = document.getElementById('gestureHome');
    if (gestureHome) gestureHome.addEventListener('click', () => {
      showToast('Home');
      showPage('pageHome');
      appendLog('adbd', 'input', 'keyevent: KEYCODE_HOME');
    });

    document.querySelectorAll('.key-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const key = btn.getAttribute('data-key');
        showToast(key + ' Key');
        appendLog('adbd', 'input', 'keyevent: ' + key);
        if (key === 'Home') showPage('pageHome');
      });
    });
    const tabAvd = document.getElementById('tabAvd');
    const tabReal = document.getElementById('tabReal');
    tabAvd.addEventListener('click', () => {
      tabAvd.classList.add('active');
      tabReal.classList.remove('active');
      document.getElementById('screenBadgeText').textContent = 'AVD EMULATOR · ARM64';
      document.getElementById('panelTitle').textContent = 'Galaxy S24 Ultra AVD';
      document.getElementById('panelSub').textContent = 'Apple Silicon Native · Android 14 (API 34)';
      document.getElementById('panelChip').textContent = '● ARM64 NATIVE';
      document.getElementById('valHost').textContent = 'Hypervisor (M5)';
      document.getElementById('valGpu').textContent = 'Metal (Host)';
      document.getElementById('specArch').textContent = 'ARM64-v8a (Zero emulation overhead)';
      document.getElementById('specRam').textContent = '8,192 MB (6 vCPU)';
      document.getElementById('btnLaunchEmu').textContent = '⚡ AVD 단독 창 실행 (galaxy-emu)';
      showToast('Switched to AVD Emulator');
      appendLog('info', 'switch', 'active profile: Galaxy_S24_Ultra.avd');
    });
    tabReal.addEventListener('click', () => {
      tabReal.classList.add('active');
      tabAvd.classList.remove('active');
      document.getElementById('screenBadgeText').textContent = 'SM-S928N · TAILSCALE';
      document.getElementById('panelTitle').textContent = 'Physical Galaxy S24 Ultra';
      document.getElementById('panelSub').textContent = 'Model SM-S928N · One UI / Android 16';
      document.getElementById('panelChip').textContent = '● REAL DEVICE';
      document.getElementById('valHost').textContent = 'Qualcomm 8 Gen 3';
      document.getElementById('valGpu').textContent = 'Adreno 750';
      document.getElementById('specArch').textContent = 'Physical Device (Knox Vault Active)';
      document.getElementById('specRam').textContent = '12 GB LPDDR5X (80% used)';
      document.getElementById('btnLaunchEmu').textContent = '🖥️ scrcpy 실물 폰 미러링';
      showToast('Switched to Real Galaxy');
      appendLog('adbd', 'switch', 'connected to SM-S928N over Tailscale');
    });
    document.getElementById('btnLaunchEmu').addEventListener('click', () => {
      if (tabAvd.classList.contains('active')) {
        showToast('Running: galaxy-emu run s24u');
        appendLog('adbd', 'exec', 'galaxy-emu run s24u -gpu host');
      } else {
        showToast('Running: scrcpy --turn-screen-off');
        appendLog('adbd', 'exec', 'scrcpy -s 100.109.128.97:39547');
      }
    });
  </script>
</body>
</html>
\`\`\`
