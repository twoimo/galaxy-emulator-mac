---
name: "galaxy-control"
description: "Unified agent control for Samsung Galaxy (Tailscale wireless ADB) and Apple Silicon ARM64 Android Virtual Devices. Provides smart indexed tap, scroll-until-found, Set-of-Marks vision, Korean/Unicode typing, notification extraction, and input clearing."
---

# Galaxy & Android Unified Control

Full specification lives in the canonical skill at
`/Users/twoimo/.aside/u/0/skills/user/galaxy-control/SKILL.md`
and is mirrored in [`twoimo/oh-my-aside`](https://github.com/twoimo/oh-my-aside/tree/main/user/galaxy-control).

## Quick surface

```bash
galaxy-emu connect                       # Tailscale wireless ADB auto-detect
galaxy-emu devices                       # physical + emulator inventory
galaxy-emu boot s24u                     # Apple Silicon ARM64 AVD (Metal GPU)
galaxy-emu uidump                        # labeled elements + tap centers (default observation)
galaxy-emu som out.png                   # Set-of-Marks numbered overlay for vision models
galaxy-emu tap 6 | tap "YouTube" | tap 720 1560
galaxy-emu find "Settings" --tap          # scroll-until-found
galaxy-emu type "한글 검색"               # Unicode via clipboard paste
galaxy-emu clear                         # wipe focused input
galaxy-emu notifications [--json]        # OTP / alert extraction
galaxy-emu mirror                        # 60fps scrcpy window, phone screen off
```

## Build the Set-of-Marks renderer

`som` needs a compiled helper (`bin/som-drawer`):

```bash
swiftc -O scripts/som_overlay.swift -o bin/som-drawer
```

## Verification status

Tested on a physical Samsung Galaxy S24 Ultra (`SM-S928N`, Android 16) over Tailscale and on
a local `emulator-5554` AVD (Android 14, arm64-v8a, 1440x3120 @505dpi) on Apple M5 Max:

| Feature | Evidence |
|---|---|
| `uidump` indexed coordinates | 15 elements with centers matched to real hits |
| `tap <index>` / `tap "label"` | opened Chrome via `[10]` and YouTube via `"YouTube"` |
| `find --tap` | located `"YouTube"` at (1224, 2135) without manual swiping |
| `type` Korean | `"최연우 갤럭시 자동화"` inserted intact |
| `clear` | `"abcdefg"` → placeholder restored |
| `notifications` | parsed title/body from live notification dump |
| `som` | 15 numbered color boxes rendered at exact bounds |
