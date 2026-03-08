#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Graph Export CLI Test
# ----------------------------------------------------------
# Validates:
#   - brain export graph
#   - brain export graph --format tsv
#   - deterministic export order
#   - CLI/module integration
# ==========================================================

cleanup() {
    rm -f "${NOTE_A:-}" "${NOTE_B:-}" 2>/dev/null || true
    brain reindex >/dev/null 2>&1 || true
}

trap 'echo "[FAIL] Unexpected error"; cleanup' ERR

echo "[TEST] Starting graph export CLI test"

: "${BRAIN_ROOT:=/data/brain}"

NOTE_A="$BRAIN_ROOT/notes/__export_cli_a__.md"
NOTE_B="$BRAIN_ROOT/notes/__export_cli_b__.md"

mkdir -p "$BRAIN_ROOT/notes"

cat > "$NOTE_A" <<'EOF'
# Export CLI A

Links:
[[__export_cli_b__.md]]
EOF

cat > "$NOTE_B" <<'EOF'
# Export CLI B
EOF

echo "[TEST] Export fixture notes created"

brain reindex >/dev/null
echo "[TEST] Reindex executed"

echo "[TEST] Running default graph export"
output_default="$(brain export graph)"

printf "%s\n" "$output_default" | grep -F "__export_cli_a__.md" >/dev/null || {
    echo "[FAIL] Missing source note in default export"
    cleanup
    exit 1
}

printf "%s\n" "$output_default" | grep -F "__export_cli_b__.md" >/dev/null || {
    echo "[FAIL] Missing target note in default export"
    cleanup
    exit 1
}

echo "[TEST] Running TSV graph export"
output_tsv="$(brain export graph --format tsv)"

printf "%s\n" "$output_tsv" | grep -F "__export_cli_a__.md" >/dev/null || {
    echo "[FAIL] Missing source note in TSV export"
    cleanup
    exit 1
}

printf "%s\n" "$output_tsv" | grep -F "__export_cli_b__.md" >/dev/null || {
    echo "[FAIL] Missing target note in TSV export"
    cleanup
    exit 1
}

sorted_output="$(printf "%s\n" "$output_tsv" | sort)"

[[ "$output_tsv" == "$sorted_output" ]] || {
    echo "[FAIL] Export output is not deterministic"
    cleanup
    exit 1
}

echo "[PASS] Graph export CLI works"

cleanup
echo "[TEST] Cleanup done"
echo "[SUCCESS] Graph export CLI test completed"
