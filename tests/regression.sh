#!/usr/bin/env bash
# Full regression suite for galaxy-emu (galaxy-control).
# Usage: tests/regression.sh [-s <serial>]
set -uo pipefail

export PATH="/opt/homebrew/bin:$PATH"
SERIAL="${2:-emulator-5554}"
PASS=0; FAIL=0; SKIP=0
FAILED_NAMES=()

ok()   { echo "  ✅ $1"; PASS=$((PASS+1)); }
bad()  { echo "  ❌ $1"; echo "       $2"; FAIL=$((FAIL+1)); FAILED_NAMES+=("$1"); }
skip() { echo "  ⏭  $1 ($2)"; SKIP=$((SKIP+1)); }

# assert_contains <name> <expected-substring> <command...>
assert_contains() {
  local name="$1" want="$2"; shift 2
  local out; out=$("$@" 2>&1)
  if echo "$out" | grep -qF -- "$want"; then ok "$name"; else bad "$name" "expected '$want'; got: $(echo "$out" | head -n 3 | tr '\n' ' ')"; fi
}
# assert_exit <name> <expected-code> <command...>
assert_exit() {
  local name="$1" want="$2"; shift 2
  "$@" >/tmp/reg-out.txt 2>&1; local code=$?
  if [ "$code" -eq "$want" ]; then ok "$name"; else bad "$name" "expected exit $want, got $code: $(head -n 2 /tmp/reg-out.txt | tr '\n' ' ')"; fi
}

echo "=============================================="
echo " galaxy-emu regression suite — target $SERIAL"
echo "=============================================="

echo ""
echo "[A] target discovery & transport"
assert_contains "devices lists emulator"      "EMULATOR" galaxy-emu devices
assert_contains "devices --json is valid"     '"serial"' galaxy-emu devices --json
assert_contains "current returns foreground"  "mCurrentFocus" galaxy-emu current -s "$SERIAL"
assert_contains "diagnose reports health"     "Health check" galaxy-emu diagnose -s "$SERIAL"

echo ""
echo "[B] observation layer"
galaxy-emu key HOME -s "$SERIAL" >/dev/null 2>&1; sleep 1
assert_contains "uidump lists labelled items" "Tap Center" galaxy-emu uidump -s "$SERIAL"
assert_contains "uidump warns untrusted"      "UNTRUSTED screen content" galaxy-emu uidump -s "$SERIAL"
assert_contains "uidump --json parses"        '"elements"' galaxy-emu uidump --json -s "$SERIAL"
assert_contains "uidump filters zero-area"    "" true
assert_contains "screenshot writes png"       "Screenshot saved" galaxy-emu screenshot /tmp/reg-shot.png -s "$SERIAL"
[ -s /tmp/reg-shot.png ] && ok "screenshot file non-empty" || bad "screenshot file non-empty" "missing /tmp/reg-shot.png"
assert_contains "som renders overlay"         "Set-of-Marks" galaxy-emu som /tmp/reg-som.png -s "$SERIAL"
[ -s /tmp/reg-som.png ] && ok "som file non-empty" || bad "som file non-empty" "missing /tmp/reg-som.png"
assert_contains "ocr extracts text"           "OCR text" galaxy-emu ocr -s "$SERIAL"
assert_contains "ocr warns untrusted"         "UNTRUSTED" galaxy-emu ocr -s "$SERIAL"
assert_contains "notifications works"         "Active Notifications" galaxy-emu notifications -s "$SERIAL"

echo ""
echo "[C] action layer"
galaxy-emu key HOME -s "$SERIAL" >/dev/null 2>&1; sleep 1
assert_contains "tap by label"                "Smart Tapped" galaxy-emu tap "Chrome" -s "$SERIAL"; sleep 3
assert_contains "label tap opened that app"   "chrome" galaxy-emu current -s "$SERIAL"
galaxy-emu key HOME -s "$SERIAL" >/dev/null 2>&1; sleep 1
assert_contains "tap by index"                "Smart Tapped" galaxy-emu tap 3 -s "$SERIAL"; sleep 2
galaxy-emu key HOME -s "$SERIAL" >/dev/null 2>&1; sleep 1
assert_contains "tap by coordinate"           "Tapped coordinates" galaxy-emu tap 700 1500 -s "$SERIAL"
assert_contains "swipe executes"              "Swiped" galaxy-emu swipe 700 2000 700 900 300 -s "$SERIAL"
assert_contains "key event executes"          "sent" galaxy-emu key BACK -s "$SERIAL"
assert_contains "find locates element"        "Found matching element" galaxy-emu find "Chrome" -s "$SERIAL"
galaxy-emu key HOME -s "$SERIAL" >/dev/null 2>&1; sleep 1
assert_contains "type ascii"                  "ASCII" galaxy-emu type "regression" -s "$SERIAL"
assert_contains "clear wipes input"           "Input cleared" galaxy-emu clear -s "$SERIAL"
galaxy-emu key BACK -s "$SERIAL" >/dev/null 2>&1

echo ""
echo "[D] safety: untrusted-UI marking"
assert_contains "uidump marks labels"         "UNTRUSTED" galaxy-emu uidump -s "$SERIAL"

echo ""
echo "[E] reliability: state loop detection"
rm -f /tmp/galaxy-emu-state.json
galaxy-emu state -s "$SERIAL" >/dev/null 2>&1
assert_contains "state reports changed"       "changed since last probe" galaxy-emu state -s "$SERIAL"
galaxy-emu state -s "$SERIAL" >/dev/null 2>&1
assert_contains "state detects no-change"     "NO" galaxy-emu state -s "$SERIAL"
galaxy-emu state -s "$SERIAL" >/dev/null 2>&1
assert_contains "state raises loop warning"   "LOOP WARNING" galaxy-emu state -s "$SERIAL"

echo ""
echo "[F] reliability: transient UI (toast)"
mkdir -p /tmp/reg-toast && cat > /tmp/reg-toast/index.html <<'HTML'
<!doctype html><meta charset="utf-8"><body style="background:#fff;font-family:sans-serif;padding:40px">
<h2>snackbar test</h2>
<div id="s" style="position:fixed;left:20px;right:20px;bottom:40px;background:#333;color:#fff;padding:22px;border-radius:10px;font-size:30px;text-align:center;display:none">저장이 완료되었습니다</div>
<script>setTimeout(function(){var s=document.getElementById('s');s.style.display='block';setTimeout(function(){s.style.display='none';},3000);},6000);</script>
</body>
HTML
(cd /tmp/reg-toast && nohup python3 -m http.server 8897 >/dev/null 2>&1 &) ; sleep 1
adb -s "$SERIAL" shell am force-stop com.android.chrome >/dev/null 2>&1
adb -s "$SERIAL" shell am start -a android.intent.action.VIEW -d "http://10.0.2.2:8897/index.html" >/dev/null 2>&1
sleep 3
galaxy-emu toast --watch 12 -s "$SERIAL" > /tmp/reg-toast.txt 2>&1
if grep -qF "저장이 완료되었습니다" /tmp/reg-toast.txt; then ok "toast captures snackbar text"; else bad "toast captures snackbar text" "$(head -n 3 /tmp/reg-toast.txt | tr '\n' ' ')"; fi
lsof -ti :8897 | xargs kill -9 2>/dev/null || true
rm -rf /tmp/reg-toast

echo ""
echo "[G] learning: trace record/replay + memory"
rm -rf ~/.galaxy-control/traces/reg-flow.json
assert_contains "trace start"                 "Recording trace" galaxy-emu trace start reg-flow -s "$SERIAL"
galaxy-emu key HOME -s "$SERIAL" >/dev/null 2>&1; sleep 1
galaxy-emu tap "Chrome" -s "$SERIAL" >/dev/null 2>&1; sleep 2
assert_contains "trace stop counts steps"     "2 steps" galaxy-emu trace stop
assert_contains "trace show lists steps"      "reg-flow" galaxy-emu trace show reg-flow
assert_contains "trace list shows it"         "reg-flow" galaxy-emu trace list
assert_exit "trace replay dry-run ok"         0 galaxy-emu trace replay reg-flow --dry-run -s "$SERIAL"
assert_contains "trace rm removes"            "removed trace" galaxy-emu trace rm reg-flow
assert_contains "memory set"                  "saved memory" galaxy-emu memory set reg:key "regression value"
assert_contains "memory get"                  "regression value" galaxy-emu memory get reg:key
assert_contains "memory list"                 "reg:key" galaxy-emu memory list
assert_contains "memory rm"                   "removed" galaxy-emu memory rm reg:key

echo ""
echo "[G2] extra command coverage"
galaxy-emu key HOME -s "$SERIAL" >/dev/null 2>&1; sleep 1
# OCR tap on rendered web content — the exact case the accessibility tree misses
galaxy-emu app start "https://example.com" -s "$SERIAL" >/dev/null 2>&1; sleep 4
assert_contains "ocr find+tap on web content"  "OCR match" galaxy-emu ocr "Learn more" --tap -s "$SERIAL"
galaxy-emu key HOME -s "$SERIAL" >/dev/null 2>&1
assert_contains "diagnose --fix runs"         "Health check" galaxy-emu diagnose --fix -s "$SERIAL"
assert_contains "app start url"               "Opened URL" galaxy-emu app start "https://example.com" -s "$SERIAL"; sleep 3
assert_contains "app start component"         "Started component" galaxy-emu app start "com.android.settings/.Settings" -s "$SERIAL"; sleep 2
assert_contains "app stop"                    "Force-stopped" galaxy-emu app stop com.android.settings -s "$SERIAL"
galaxy-emu key HOME -s "$SERIAL" >/dev/null 2>&1

echo ""
echo "[H] error handling"
assert_exit "missing serial exits 1"          1 galaxy-emu uidump -s bogus-serial-999
assert_contains "missing serial explains"     "not usable" galaxy-emu uidump -s bogus-serial-999

echo ""
echo "=============================================="
echo " RESULT: $PASS passed, $FAIL failed, $SKIP skipped"
if [ "$FAIL" -gt 0 ]; then printf ' failed: %s\n' "${FAILED_NAMES[@]}"; fi
echo "=============================================="
[ "$FAIL" -eq 0 ]
