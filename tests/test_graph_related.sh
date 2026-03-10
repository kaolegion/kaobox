#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# KAOBOX GRAPH RELATED TEST
# Phase 3.7 - Related Notes Command
# ==========================================

trap 'echo "[FAIL] Unexpected error"; rm -f "$FOCUS_NOTE" "$OUT_NOTE" "$IN_NOTE"' ERR

echo "[TEST] Starting graph related test"

: "${BRAIN_ROOT:=/data/brain}"

FOCUS_NOTE="$BRAIN_ROOT/notes/__related_focus__.md"
OUT_NOTE="$BRAIN_ROOT/notes/__related_out__.md"
IN_NOTE="$BRAIN_ROOT/notes/__related_in__.md"

cat > "$FOCUS_NOTE" <<'NOTE'
# Related Focus

Links:
[[__related_out__.md]]
NOTE

cat > "$OUT_NOTE" <<'NOTE'
# Related Out

Direct outgoing related note.
NOTE

cat > "$IN_NOTE" <<'NOTE'
# Related In

Links:
[[__related_focus__.md]]
NOTE

echo "[TEST] Related notes created"

brain reindex >/dev/null
echo "[TEST] Reindex executed"

output="$(brain related __related_focus__.md)"

echo "$output" | grep -F "Related" >/dev/null || {
    echo "[FAIL] Missing related header"
    exit 1
}

echo "$output" | grep -F "__related_in__.md" >/dev/null || {
    echo "[FAIL] Missing incoming related note"
    exit 1
}

echo "$output" | grep -F "__related_out__.md" >/dev/null || {
    echo "[FAIL] Missing outgoing related note"
    exit 1
}

distance_count="$(printf "%s\n" "$output" | grep -c '^\[d=1\]')"
[[ "$distance_count" -eq 2 ]] || {
    echo "[FAIL] Expected 2 direct related notes, got $distance_count"
    exit 1
}

sorted_related="$(printf "%s\n" "$output" | grep '^\[d=' | sort)"
actual_related="$(printf "%s\n" "$output" | grep '^\[d=')"
[[ "$actual_related" == "$sorted_related" ]] || {
    echo "[FAIL] Related output is not deterministic"
    exit 1
}

echo "[PASS] Related command works"

rm -f "$FOCUS_NOTE" "$OUT_NOTE" "$IN_NOTE"
brain reindex >/dev/null

echo "[TEST] Cleanup done"
echo "[SUCCESS] Graph related test completed"
