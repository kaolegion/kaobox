#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# TEST: Think engine graph-aware ranking
# Phase 3.5 - Graph boost integration
# Phase 3.8 - Configurable graph weighting
# ==========================================================

trap 'echo "[FAIL] Unexpected error"; rm -f "$FOCUS_NOTE" "$NEIGHBOR_NOTE" "$OTHER_NOTE"' ERR

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "$ROOT_DIR/lib/brain/env.sh"

echo "[TEST] Starting think graph boost test"

FOCUS_NOTE="$BRAIN_ROOT/notes/__think_focus__.md"
NEIGHBOR_NOTE="$BRAIN_ROOT/notes/__think_neighbor__.md"
OTHER_NOTE="$BRAIN_ROOT/notes/__think_other__.md"

cat > "$FOCUS_NOTE" <<'EOF_FOCUS'
# Think Focus

Links:
[[__think_neighbor__.md]]
EOF_FOCUS

cat > "$NEIGHBOR_NOTE" <<'EOF_NEIGHBOR'
# Think Neighbor

sharedgraphterm
EOF_NEIGHBOR

cat > "$OTHER_NOTE" <<'EOF_OTHER'
# Think Other

sharedgraphterm
EOF_OTHER

echo "[TEST] Think notes created"

brain reindex >/dev/null
echo "[TEST] Reindex executed"

brain session start "$FOCUS_NOTE" >/dev/null 2>&1 || true
brain session focus "$FOCUS_NOTE" >/dev/null 2>&1 || true

unset BRAIN_THINK_GRAPH_BOOST || true
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

# ----------------------------------------------------------
# Additive runtime override verification
# ----------------------------------------------------------
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/brain/think/ranker.sh"

THINK_GRAPH_PATHS="$NEIGHBOR_NOTE"$'\n'"$OTHER_NOTE"
export THINK_GRAPH_PATHS

default_graph_boost="$(graph_boost_for_path "$NEIGHBOR_NOTE" "$THINK_GRAPH_PATHS")"
[[ "$default_graph_boost" == "2" ]] || {
    echo "[FAIL] Expected default graph boost to remain 2"
    echo "Actual: $default_graph_boost"
    exit 1
}

echo "[PASS] Default graph boost remains unchanged"

export BRAIN_THINK_GRAPH_BOOST="9"
override_graph_boost="$(graph_boost_for_path "$NEIGHBOR_NOTE" "$THINK_GRAPH_PATHS")"
[[ "$override_graph_boost" == "9" ]] || {
    echo "[FAIL] Expected BRAIN_THINK_GRAPH_BOOST override to be applied"
    echo "Actual: $override_graph_boost"
    exit 1
}

echo "[PASS] Runtime graph boost override works"

export BRAIN_THINK_GRAPH_BOOST="invalid"
invalid_override_graph_boost="$(graph_boost_for_path "$NEIGHBOR_NOTE" "$THINK_GRAPH_PATHS")"
[[ "$invalid_override_graph_boost" == "2" ]] || {
    echo "[FAIL] Expected invalid override to fall back to THINK_GRAPH_BOOST"
    echo "Actual: $invalid_override_graph_boost"
    exit 1
}

echo "[PASS] Invalid runtime override falls back deterministically"

unset BRAIN_THINK_GRAPH_BOOST || true
unset THINK_GRAPH_PATHS || true

rm -f "$FOCUS_NOTE" "$NEIGHBOR_NOTE" "$OTHER_NOTE"
brain reindex >/dev/null

echo "[TEST] Cleanup done"
echo "[SUCCESS] Think graph boost test completed"
