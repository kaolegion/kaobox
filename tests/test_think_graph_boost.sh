#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# TEST: Think engine graph-aware ranking
# Phase 3.5 - Graph boost integration
# ==========================================================

trap 'echo "[FAIL] Unexpected error"; rm -f "$FOCUS_NOTE" "$NEIGHBOR_NOTE" "$OTHER_NOTE"' ERR

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "$ROOT_DIR/lib/brain/env.sh"

echo "[TEST] Starting think graph boost test"

FOCUS_NOTE="$BRAIN_ROOT/notes/__think_focus__.md"
NEIGHBOR_NOTE="$BRAIN_ROOT/notes/__think_neighbor__.md"
OTHER_NOTE="$BRAIN_ROOT/notes/__think_other__.md"

cat > "$FOCUS_NOTE" <<'EOF'
# Think Focus

Links:
[[__think_neighbor__.md]]
EOF

cat > "$NEIGHBOR_NOTE" <<'EOF'
# Think Neighbor

sharedgraphterm
EOF

cat > "$OTHER_NOTE" <<'EOF'
# Think Other

sharedgraphterm
EOF

echo "[TEST] Think notes created"

brain reindex >/dev/null
echo "[TEST] Reindex executed"

brain session start "$FOCUS_NOTE" >/dev/null 2>&1 || true
brain session focus "$FOCUS_NOTE" >/dev/null 2>&1 || true

output="$(brain think sharedgraphterm)"

echo "$output" | grep -F "__think_neighbor__.md" >/dev/null || {
    echo "[FAIL] Missing neighbor result"
    exit 1
}

echo "$output" | grep -F "__think_other__.md" >/dev/null || {
    echo "[FAIL] Missing other result"
    exit 1
}

first_path="$(printf "%s\n" "$output" | awk -F'\t' 'NF >= 2 {print $2; exit}')"

[[ "$first_path" == *"__think_neighbor__.md" ]] || {
    echo "[FAIL] Expected graph neighbor to rank first"
    echo "$output"
    exit 1
}

echo "[PASS] Graph-aware ranking works"

rm -f "$FOCUS_NOTE" "$NEIGHBOR_NOTE" "$OTHER_NOTE"
brain reindex >/dev/null

echo "[TEST] Cleanup done"
echo "[SUCCESS] Think graph boost test completed"
