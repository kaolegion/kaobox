#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# KAOBOX GRAPH NAVIGATION TEST
# Phase 3.4 - Direct Graph Queries
# ==========================================

trap 'echo "[FAIL] Unexpected error"; rm -f "$NOTE_A" "$NOTE_B" "$NOTE_C"' ERR

echo "[TEST] Starting graph navigation test"

: "${BRAIN_ROOT:=/data/brain}"

NOTE_A="$BRAIN_ROOT/notes/__graph_a__.md"
NOTE_B="$BRAIN_ROOT/notes/__graph_b__.md"
NOTE_C="$BRAIN_ROOT/notes/__graph_c__.md"

cat > "$NOTE_A" <<'EOF'
# Graph A

Tags: #graph

Links:
[[__graph_b__.md]]
EOF

cat > "$NOTE_B" <<'EOF'
# Graph B

Tags: #graph

Links:
[[__graph_c__.md]]
EOF

cat > "$NOTE_C" <<'EOF'
# Graph C

Tags: #graph
EOF

echo "[TEST] Graph notes created"

brain reindex >/dev/null
echo "[TEST] Reindex executed"

echo "[TEST] brain graph"
brain graph __graph_b__.md >/dev/null

echo "[TEST] brain backlinks"
brain backlinks __graph_b__.md >/dev/null

echo "[TEST] brain neighbors"
brain neighbors __graph_b__.md >/dev/null

echo "[PASS] Graph commands executed"

rm -f "$NOTE_A" "$NOTE_B" "$NOTE_C"
brain reindex >/dev/null

echo "[TEST] Cleanup done"
echo "[SUCCESS] Graph navigation test completed"
