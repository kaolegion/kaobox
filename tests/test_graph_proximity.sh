#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# KAOBOX GRAPH PROXIMITY TEST
# Phase 3.5 - Direct Graph Proximity Query
# ==========================================

trap 'echo "[FAIL] Unexpected error"; rm -f "$FOCUS_NOTE" "$OUT_NOTE" "$IN_NOTE"' ERR

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Brain runtime environment
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/brain/env.sh"

# Query layer only
# shellcheck source=/dev/null
source "$ROOT_DIR/modules/memory/query.sh"

echo "[TEST] Starting graph proximity test"

FOCUS_NOTE="$BRAIN_ROOT/notes/__graph_focus__.md"
OUT_NOTE="$BRAIN_ROOT/notes/__graph_out__.md"
IN_NOTE="$BRAIN_ROOT/notes/__graph_in__.md"

cat > "$FOCUS_NOTE" <<'EOF'
# Graph Focus

Links:
[[__graph_out__.md]]
EOF

cat > "$OUT_NOTE" <<'EOF'
# Graph Out

Direct outgoing neighbor.
EOF

cat > "$IN_NOTE" <<'EOF'
# Graph In

Links:
[[__graph_focus__.md]]
EOF

echo "[TEST] Proximity notes created"

brain reindex >/dev/null
echo "[TEST] Reindex executed"

focus_id="$(sqlite3 -batch -noheader "$BRAIN_DB" \
    "SELECT id FROM notes WHERE path = '$FOCUS_NOTE' LIMIT 1;")"

[[ -n "${focus_id:-}" ]] || {
    echo "[FAIL] Could not resolve focus note id"
    exit 1
}

output="$(query_graph_proximity_by_note "$focus_id")"

echo "$output" | grep -F "__graph_in__.md" >/dev/null || {
    echo "[FAIL] Missing incoming neighbor"
    exit 1
}

echo "$output" | grep -F "__graph_out__.md" >/dev/null || {
    echo "[FAIL] Missing outgoing neighbor"
    exit 1
}

dist_count="$(printf "%s\n" "$output" | awk -F'\t' '$4 == 1 {count++} END {print count+0}')"
[[ "$dist_count" -eq 2 ]] || {
    echo "[FAIL] Expected distance 1 for all neighbors"
    exit 1
}

line_count="$(printf "%s\n" "$output" | sed '/^$/d' | wc -l | tr -d ' ')"
[[ "$line_count" -eq 2 ]] || {
    echo "[FAIL] Expected exactly 2 neighbors, got $line_count"
    exit 1
}

sorted_output="$(printf "%s\n" "$output" | sort)"
[[ "$output" == "$sorted_output" ]] || {
    echo "[FAIL] Output is not deterministic"
    exit 1
}

echo "[PASS] Graph proximity query works"

rm -f "$FOCUS_NOTE" "$OUT_NOTE" "$IN_NOTE"
brain reindex >/dev/null

echo "[TEST] Cleanup done"
echo "[SUCCESS] Graph proximity test completed"
