#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# KAOBOX GRAPH PATH TEST
# Phase 3.4 - Graph Path Traversal
# ==========================================

trap 'echo "[FAIL] Unexpected error"; rm -f "$NOTE_A" "$NOTE_B" "$NOTE_C" "$NOTE_D"' ERR

echo "[TEST] Starting graph path test"

: "${BRAIN_ROOT:=/data/brain}"

NOTE_A="$BRAIN_ROOT/notes/__path_a__.md"
NOTE_B="$BRAIN_ROOT/notes/__path_b__.md"
NOTE_C="$BRAIN_ROOT/notes/__path_c__.md"
NOTE_D="$BRAIN_ROOT/notes/__path_d__.md"

cat > "$NOTE_A" <<'EOF'
# Path A

Links:
[[__path_b__.md]]
EOF

cat > "$NOTE_B" <<'EOF'
# Path B

Links:
[[__path_c__.md]]
EOF

cat > "$NOTE_C" <<'EOF'
# Path C

Links:
[[__path_d__.md]]
EOF

cat > "$NOTE_D" <<'EOF'
# Path D
EOF

echo "[TEST] Path notes created"

brain reindex >/dev/null
echo "[TEST] Reindex executed"

echo "[TEST] brain path"
brain path __path_a__.md __path_d__.md >/dev/null

echo "[PASS] Graph path executed"

rm -f "$NOTE_A" "$NOTE_B" "$NOTE_C" "$NOTE_D"
brain reindex >/dev/null

echo "[TEST] Cleanup done"
echo "[SUCCESS] Graph path test completed"
