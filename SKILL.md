---
name: "galaxy-emulator"
description: "Agent-first automation, observation, and control for Samsung Galaxy devices (S24 Ultra via Tailscale/USB) and Apple Silicon ARM64 Android Virtual Devices (emulator-5554)."
---

# Galaxy Emulator & Device Control (Agent-First Specification)

This skill provides a deterministic, reliable command-line interface for any LLM agent (Aside Browser, ChatGPT Desktop / Codex, Grok Bot, Claude Code) to inspect, automate, and control both **physical Samsung Galaxy smartphones** and **Apple Silicon ARM64 Android Virtual Devices (AVD)**.

---

## 🧭 Device Topology & Routing

| Device Target | Serial Identifier | Execution Surface | Characteristics |
|---|---|---|---|
| **Virtual AVD Machine** | `emulator-5554` | Apple Silicon Hypervisor (M5 Max) | Isolated clean OS, zero personal risk, root/writable access, fast snapshots |
| **Physical Galaxy Phone** | `100.109.128.97:39547` (or USB serial) | Real Galaxy Hardware (SM-S928N, Android 16) | Knox Vault, banking, KakaoTalk, production environment. Use `--turn-screen-off` |

### Target Selection Rule
- If the user asks for testing, disposable APK runs, or general Android automation, prefer **`emulator-5554`**.
- If the user explicitly asks for their personal phone, production apps (KakaoTalk, Samsung Pay), use the **Physical Serial**.
- All commands accept `-s <serial>` to route to an explicit target. If omitted, `galaxy-emu` auto-targets the active emulator first, then connected devices.

---

## 🛠️ Unified Agent Command Surface (`galaxy-emu`)

All commands are available globally in PATH:
```bash
export PATH="/opt/homebrew/bin:$PATH"
```

### 1. Device Discovery & Health Check
```bash
# List all active devices and emulators
galaxy-emu devices

# JSON output for machine parsing
galaxy-emu devices --json

# Get current foreground package and activity
galaxy-emu current -s emulator-5554
```

### 2. Observation Loop (Inspect What is on Screen)
LLMs must ground their actions in verified observation rather than guessing coordinates:

```bash
# A. High-resolution screenshot capture
galaxy-emu screenshot /tmp/screen.png -s emulator-5554

# B. Dump interactive UI hierarchy with exact bounding boxes & center coordinates
galaxy-emu uidump -s emulator-5554

# C. Machine-readable JSON UI tree for automated element finding
galaxy-emu uidump --json -s emulator-5554
```
*`uidump` returns the clickable elements with their text, content-desc, resource-id, and center `(x, y)` tap coordinates.*

### 3. Action Execution (Touch, Keys, Text)
```bash
# Exact tap on coordinate
galaxy-emu tap 720 1560 -s emulator-5554

# Swipe / scroll (x1 y1 x2 y2 duration_ms)
galaxy-emu swipe 720 2000 720 800 300 -s emulator-5554

# Type text into focused input (auto-escapes spaces and special characters)
galaxy-emu type "Hello World" -s emulator-5554

# Hardware key events: HOME, BACK, POWER, ENTER, APP_SWITCH, VOL_UP, VOL_DOWN
galaxy-emu key HOME -s emulator-5554
galaxy-emu key BACK -s emulator-5554
galaxy-emu key ENTER -s emulator-5554
```

### 4. App & URL Management
```bash
# Open URL directly in default browser
galaxy-emu app start "https://youtube.com" -s emulator-5554

# Start specific app activity component
galaxy-emu app start "com.android.chrome/com.google.android.apps.chrome.Main" -s emulator-5554

# Force stop an app
galaxy-emu app stop "com.google.android.youtube" -s emulator-5554

# Install APK
galaxy-emu install "/path/to/app.apk" -s emulator-5554
```

### 5. Physical Device Mirroring (`scrcpy`)
To let the user watch and interact with their physical phone on the macOS desktop:
```bash
# Launches low-latency 60fps window on macOS with phone screen turned off
galaxy-emu mirror -s 100.109.128.97:39547
```

---

## 🤖 LLM Agent Execution Guidelines

1. **Verify State Before and After Action**:
   - Before tapping, run `galaxy-emu current` or `galaxy-emu uidump` to confirm the target element is visible.
   - After tapping or typing, verify the resulting screen via `galaxy-emu current` or a quick screenshot check.
2. **Never Wake Physical Screen Unnecessarily**:
   - Always operate physical phones via background ADB or `scrcpy --turn-screen-off` to protect user privacy and battery.
3. **Handle Permissions & Popups**:
   - When launching apps for the first time, check `uidump` for Android permission request dialogs and tap "Allow" / "While using the app" coordinates.
4. **Deterministic Exit**:
   - Report the exact serial operated (`emulator-5554` or physical model), the actions taken, and the verified resulting state.
