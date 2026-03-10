#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# TEST: Think engine graph-aware ranking
# Phase 3.5 - Graph boost integration
# Phase 3.8 - Configurable graph weighting
# Phase 3.8.b - Path-aware context expansion
# ==========================================================

trap 'echo "[FAIL] Unexpected error"; rm -f "$FOCUS_NOTE" "$NEIGHBOR_NOTE" "$INDIRECT_NOTE" "$FAR_NOTE" "$OTHER_NOTE"' ERR

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "$ROOT_DIR/lib/brain/env.sh"

echo "[TEST] Starting think graph boost test"

FOCUS_NOTE="$BRAIN_ROOT/notes/__think_focus__.md"
NEIGHBOR_NOTE="$BRAIN_ROOT/notes/__think_neighbor__.md"
INDIRECT_NOTE="$BRAIN_ROOT/notes/__think_indirect__.md"
FAR_NOTE="$BRAIN_ROOT/notes/__think_far__.md"
OTHER_NOTE="$BRAIN_ROOT/notes/__think_other__.md"

cat > "$FOCUS_NOTE" <<'EOF_FOCUS'
# Think Focus

Links:
[[__think_neighbor__.md]]
EOF_FOCUS

cat > "$NEIGHBOR_NOTE" <<'EOF_NEIGHBOR'
# Think Neighbor

sharedgraphterm

Links:
[[__think_indirect__.md]]
EOF_NEIGHBOR

cat > "$INDIRECT_NOTE" <<'EOF_INDIRECT'
# Think Indirect

sharedgraphterm

Links:
[[__think_far__.md]]
EOF_INDIRECT

cat > "$FAR_NOTE" <<'EOF_FAR'
# Think Far

sharedgraphterm
EOF_FAR

cat > "$OTHER_NOTE" <<'EOF_OTHER'
# Think Other

sharedgraphterm
EOF_OTHER

echo "[TEST] Think notes created"

brain reindex >/dev/null
echo "[TEST] Reindex executed"

brain focus "$FOCUS_NOTE" >/dev/null

active_focus="$(cat "$BRAIN_ROOT/.session" 2>/dev/null || true)"
[[ "$active_focus" == "$FOCUS_NOTE" ]] || {
    echo "[FAIL] Expected active focus to be set to test focus note"
    echo "Actual: $active_focus"
    exit 1
}

unset BRAIN_THINK_GRAPH_BOOST || true
output="$(brain think sharedgraphterm)"

echo "$output" | grep -F "__think_neighbor__.md" >/dev/null || {
    echo "[FAIL] Missing neighbor result"
    exit 1
}

echo "$output" | grep -F "__think_indirect__.md" >/dev/null || {
    echo "[FAIL] Missing indirect result"
    exit 1
}

echo "$output" | grep -F "__think_far__.md" >/dev/null || {
    echo "[FAIL] Missing far result"
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

neighbor_line="$(printf "%s\n" "$output" | nl -ba | awk '/__think_neighbor__\.md/ {print $1; exit}')"
indirect_line="$(printf "%s\n" "$output" | nl -ba | awk '/__think_indirect__\.md/ {print $1; exit}')"
far_line="$(printf "%s\n" "$output" | nl -ba | awk '/__think_far__\.md/ {print $1; exit}')"
other_line="$(printf "%s\n" "$output" | nl -ba | awk '/__think_other__\.md/ {print $1; exit}')"

[[ -n "$neighbor_line" && -n "$indirect_line" && -n "$far_line" && -n "$other_line" ]] || {
    echo "[FAIL] Could not resolve output ordering"
    echo "$output"
    exit 1
}

(( indirect_line < other_line )) || {
    echo "[FAIL] Expected indirect path result to rank above unrelated result"
    echo "$output"
    exit 1
}

(( far_line < other_line )) || {
    echo "[FAIL] Expected far path result to rank above unrelated result"
    echo "$output"
    exit 1
}

echo "[PASS] Path-aware graph ranking works"

# ----------------------------------------------------------
# Binary compatibility: direct graph path boost
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

# ----------------------------------------------------------
# Path-aware context weighting
# ----------------------------------------------------------
THINK_GRAPH_CONTEXT=$'1\t'"$NEIGHBOR_NOTE"$'\tThink Neighbor\t1\n2\t'"$INDIRECT_NOTE"$'\tThink Indirect\t2\n3\t'"$FAR_NOTE"$'\tThink Far\t3'
export THINK_GRAPH_CONTEXT

unset BRAIN_THINK_GRAPH_BOOST || true

context_neighbor_boost="$(graph_boost_for_context_path "$NEIGHBOR_NOTE" "$THINK_GRAPH_CONTEXT")"
context_indirect_boost="$(graph_boost_for_context_path "$INDIRECT_NOTE" "$THINK_GRAPH_CONTEXT")"
context_far_boost="$(graph_boost_for_context_path "$FAR_NOTE" "$THINK_GRAPH_CONTEXT")"

[[ "$context_neighbor_boost" == "2" ]] || {
    echo "[FAIL] Expected distance-1 context boost to be 2"
    echo "Actual: $context_neighbor_boost"
    exit 1
}

[[ "$context_indirect_boost" == "1" ]] || {
    echo "[FAIL] Expected distance-2 context boost to decay to 1"
    echo "Actual: $context_indirect_boost"
    exit 1
}

[[ "$context_far_boost" == "1" ]] || {
    echo "[FAIL] Expected distance-3 context boost to decay to 1"
    echo "Actual: $context_far_boost"
    exit 1
}

echo "[PASS] Default path-aware context weighting works"

export BRAIN_THINK_GRAPH_BOOST="4"

override_context_neighbor_boost="$(graph_boost_for_context_path "$NEIGHBOR_NOTE" "$THINK_GRAPH_CONTEXT")"
override_context_indirect_boost="$(graph_boost_for_context_path "$INDIRECT_NOTE" "$THINK_GRAPH_CONTEXT")"
override_context_far_boost="$(graph_boost_for_context_path "$FAR_NOTE" "$THINK_GRAPH_CONTEXT")"

[[ "$override_context_neighbor_boost" == "4" ]] || {
    echo "[FAIL] Expected distance-1 override context boost to be 4"
    echo "Actual: $override_context_neighbor_boost"
    exit 1
}

[[ "$override_context_indirect_boost" == "3" ]] || {
    echo "[FAIL] Expected distance-2 override context boost to be 3"
    echo "Actual: $override_context_indirect_boost"
    exit 1
}

[[ "$override_context_far_boost" == "2" ]] || {
    echo "[FAIL] Expected distance-3 override context boost to be 2"
    echo "Actual: $override_context_far_boost"
    exit 1
}

echo "[PASS] Override path-aware context weighting works"

unset BRAIN_THINK_GRAPH_BOOST || true
unset THINK_GRAPH_PATHS || true
unset THINK_GRAPH_CONTEXT || true

rm -f "$FOCUS_NOTE" "$NEIGHBOR_NOTE" "$INDIRECT_NOTE" "$FAR_NOTE" "$OTHER_NOTE"
brain reindex >/dev/null

echo "[TEST] Cleanup done"
echo "[SUCCESS] Think graph boost test completed"
