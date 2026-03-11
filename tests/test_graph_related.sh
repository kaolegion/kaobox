#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# KAOBOX GRAPH RELATED TEST
# Phase 3.7 - Related Notes Command
# Phase 3.8.c - Ambiguous Note Resolution
# ==========================================

cleanup() {
    rm -f "$FOCUS_NOTE" "$OUT_NOTE" "$IN_NOTE" "$AMBIG_NOTE_A" "$AMBIG_NOTE_B"
    rmdir --ignore-fail-on-non-empty "$(dirname "$AMBIG_NOTE_A")" "$(dirname "$AMBIG_NOTE_B")" 2>/dev/null || true
    brain reindex >/dev/null 2>&1 || true
}

on_error() {
    echo "[FAIL] Unexpected error"
    cleanup
    exit 1
}

trap on_error ERR

echo "[TEST] Starting graph related test"

: "${BRAIN_ROOT:=/data/brain}"

FOCUS_NOTE="$BRAIN_ROOT/notes/__related_focus__.md"
OUT_NOTE="$BRAIN_ROOT/notes/__related_out__.md"
IN_NOTE="$BRAIN_ROOT/notes/__related_in__.md"
AMBIG_NOTE_A="$BRAIN_ROOT/notes/area-one/__related_ambiguous__.md"
AMBIG_NOTE_B="$BRAIN_ROOT/notes/area-two/__related_ambiguous__.md"

mkdir -p "$(dirname "$AMBIG_NOTE_A")" "$(dirname "$AMBIG_NOTE_B")"

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

cat > "$AMBIG_NOTE_A" <<'NOTE'
# Shared Ambiguous Title

Ambiguous candidate A.
NOTE

cat > "$AMBIG_NOTE_B" <<'NOTE'
# Shared Ambiguous Title

Ambiguous candidate B.
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

trap - ERR
set +e
ambiguous_output="$(brain related "__related_ambiguous__.md" 2>&1)"
ambiguous_status=$?
set -e
trap on_error ERR

[[ "$ambiguous_status" -ne 0 ]] || {
    echo "[FAIL] Expected ambiguous related lookup to fail"
    exit 1
}

printf "%s\n" "$ambiguous_output" | grep -F "Ambiguous note reference: __related_ambiguous__.md" >/dev/null || {
    echo "[FAIL] Missing ambiguous reference error"
    echo "$ambiguous_output"
    exit 1
}

printf "%s\n" "$ambiguous_output" | grep -F "area-one/__related_ambiguous__.md" >/dev/null || {
    echo "[FAIL] Missing first ambiguous candidate"
    echo "$ambiguous_output"
    exit 1
}

printf "%s\n" "$ambiguous_output" | grep -F "area-two/__related_ambiguous__.md" >/dev/null || {
    echo "[FAIL] Missing second ambiguous candidate"
    echo "$ambiguous_output"
    exit 1
}

echo "[PASS] Ambiguous related lookup is rejected deterministically"

cleanup

echo "[TEST] Cleanup done"
echo "[SUCCESS] Graph related test completed"
