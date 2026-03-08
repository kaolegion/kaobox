#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX GRAPH EXPORT TEST
# Phase 3.6 - Canonical Graph Export Groundwork
# ==========================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ----------------------------------------------------------
# Brain runtime environment
# ----------------------------------------------------------
# shellcheck source=/dev/null
source "$ROOT_DIR/lib/brain/env.sh"

# ----------------------------------------------------------
# Export layer under test
# ----------------------------------------------------------
# shellcheck source=/dev/null
source "$ROOT_DIR/modules/memory/export.sh"

NOTE_A="$BRAIN_ROOT/notes/__export_a__.md"
NOTE_B="$BRAIN_ROOT/notes/__export_b__.md"
NOTE_C="$BRAIN_ROOT/notes/__export_c__.md"

cleanup() {
    rm -f "$NOTE_A" "$NOTE_B" "$NOTE_C"
    brain reindex >/dev/null 2>&1 || true
}

trap 'echo "[FAIL] Unexpected error"; cleanup; exit 1' ERR
trap cleanup EXIT

echo "[TEST] Starting graph export test"

cat > "$NOTE_A" <<'EOF'
# Export A

Links:
[[__export_b__.md]]
[[__export_c__.md]]
EOF

cat > "$NOTE_B" <<'EOF'
# Export B

Links:
[[__export_c__.md]]
EOF

cat > "$NOTE_C" <<'EOF'
# Export C
EOF

echo "[TEST] Export notes created"

brain reindex >/dev/null
echo "[TEST] Reindex executed"

output_1="$(export_graph_edges_tsv)"
output_2="$(export_graph_edges_tsv)"

[[ -n "${output_1:-}" ]] || {
    echo "[FAIL] Export returned no data"
    exit 1
}

filter_test_edges() {
    grep -F "$BRAIN_ROOT/notes/__export_" || true
}

test_output_1="$(printf "%s\n" "$output_1" | filter_test_edges)"
test_output_2="$(printf "%s\n" "$output_2" | filter_test_edges)"

expected="$(cat <<EOF
$NOTE_A	$NOTE_B
$NOTE_A	$NOTE_C
$NOTE_B	$NOTE_C
EOF
)"

# ----------------------------------------------------------
# Exact expected output for test subset only
# ----------------------------------------------------------
if [[ "$test_output_1" != "$expected" ]]; then
    echo "[FAIL] Export subset output mismatch"
    echo
    echo "[EXPECTED]"
    printf "%s\n" "$expected"
    echo
    echo "[GOT]"
    printf "%s\n" "$test_output_1"
    exit 1
fi

echo "[PASS] Export subset matches expected edges"

# ----------------------------------------------------------
# Determinism on test subset
# ----------------------------------------------------------
if [[ "$test_output_1" != "$test_output_2" ]]; then
    echo "[FAIL] Export subset is not deterministic"
    exit 1
fi

echo "[PASS] Export subset is deterministic"

# ----------------------------------------------------------
# Count validation on test subset
# ----------------------------------------------------------
subset_count="$(printf "%s\n" "$test_output_1" | sed '/^$/d' | wc -l | tr -d ' ')"
[[ "$subset_count" == "3" ]] || {
    echo "[FAIL] Expected 3 test edges, got $subset_count"
    exit 1
}

echo "[PASS] Test subset edge count is correct"

# ----------------------------------------------------------
# Sorted output validation on test subset
# ----------------------------------------------------------
sorted_output="$(printf "%s\n" "$test_output_1" | sort)"
[[ "$test_output_1" == "$sorted_output" ]] || {
    echo "[FAIL] Export subset is not canonically sorted"
    exit 1
}

echo "[PASS] Export subset ordering is canonical"

echo "[SUCCESS] Graph export test completed"
