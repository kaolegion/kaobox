#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - CLI REGRESSION CONTRACT TEST
# ----------------------------------------------------------
# Goal:
#   - Lock graph-facing CLI contract
#   - Lock cognition-facing CLI contract
#   - Validate dispatcher-level error propagation
#   - Keep fixtures deterministic and isolated
# ==========================================================

cleanup() {
    rm -f \
      "$FOCUS_NOTE" \
      "$OUT_NOTE" \
      "$IN_NOTE" \
      "$PATH_MID_NOTE" \
      "$PATH_END_NOTE" \
      "$THINK_OTHER_NOTE" \
      "$AMBIG_NOTE_A" \
      "$AMBIG_NOTE_B"
    rmdir --ignore-fail-on-non-empty \
      "$(dirname "$AMBIG_NOTE_A")" \
      "$(dirname "$AMBIG_NOTE_B")" \
      2>/dev/null || true
    brain reindex >/dev/null 2>&1 || true
}

on_error() {
    echo "[FAIL] Unexpected error"
    cleanup
    exit 1
}

trap on_error ERR

echo "[TEST] Starting CLI regression contract test"

: "${BRAIN_ROOT:=/data/brain}"

FOCUS_NOTE="$BRAIN_ROOT/notes/__cli_contract_focus__.md"
OUT_NOTE="$BRAIN_ROOT/notes/__cli_contract_out__.md"
IN_NOTE="$BRAIN_ROOT/notes/__cli_contract_in__.md"
PATH_MID_NOTE="$BRAIN_ROOT/notes/__cli_contract_path_mid__.md"
PATH_END_NOTE="$BRAIN_ROOT/notes/__cli_contract_path_end__.md"
THINK_OTHER_NOTE="$BRAIN_ROOT/notes/__cli_contract_other__.md"
AMBIG_NOTE_A="$BRAIN_ROOT/notes/contract-a/__cli_contract_ambiguous__.md"
AMBIG_NOTE_B="$BRAIN_ROOT/notes/contract-b/__cli_contract_ambiguous__.md"

mkdir -p "$(dirname "$AMBIG_NOTE_A")" "$(dirname "$AMBIG_NOTE_B")"

cat > "$FOCUS_NOTE" <<'NOTE'
# CLI Contract Focus

sharedcontractterm

Links:
[[__cli_contract_out__.md]]
[[__cli_contract_path_mid__.md]]
NOTE

cat > "$OUT_NOTE" <<'NOTE'
# CLI Contract Out

sharedcontractterm
NOTE

cat > "$IN_NOTE" <<'NOTE'
# CLI Contract In

Links:
[[__cli_contract_focus__.md]]
NOTE

cat > "$PATH_MID_NOTE" <<'NOTE'
# CLI Contract Path Mid

sharedcontractterm

Links:
[[__cli_contract_path_end__.md]]
NOTE

cat > "$PATH_END_NOTE" <<'NOTE'
# CLI Contract Path End

sharedcontractterm
NOTE

cat > "$THINK_OTHER_NOTE" <<'NOTE'
# CLI Contract Other

sharedcontractterm
NOTE

cat > "$AMBIG_NOTE_A" <<'NOTE'
# CLI Contract Ambiguous

Candidate A.
NOTE

cat > "$AMBIG_NOTE_B" <<'NOTE'
# CLI Contract Ambiguous

Candidate B.
NOTE

echo "[TEST] CLI contract notes created"

brain reindex >/dev/null
echo "[TEST] Reindex executed"

brain focus "$FOCUS_NOTE" >/dev/null
echo "[TEST] Focus set"

# ----------------------------------------------------------
# Graph-facing success contract
# ----------------------------------------------------------
graph_output="$(brain graph __cli_contract_focus__.md)"
printf "%s\n" "$graph_output" | grep -F "__cli_contract_out__.md" >/dev/null || {
    echo "[FAIL] brain graph missing outgoing linked note"
    echo "$graph_output"
    exit 1
}
printf "%s\n" "$graph_output" | grep -F "__cli_contract_path_mid__.md" >/dev/null || {
    echo "[FAIL] brain graph missing second outgoing linked note"
    echo "$graph_output"
    exit 1
}
printf "%s\n" "$graph_output" | grep -F "__cli_contract_in__.md" >/dev/null || {
    echo "[FAIL] brain graph missing incoming linked note"
    echo "$graph_output"
    exit 1
}
echo "[PASS] brain graph CLI contract works"

backlinks_output="$(brain backlinks __cli_contract_focus__.md)"
printf "%s\n" "$backlinks_output" | grep -F "__cli_contract_in__.md" >/dev/null || {
    echo "[FAIL] brain backlinks missing backlink note"
    echo "$backlinks_output"
    exit 1
}
echo "[PASS] brain backlinks CLI contract works"

neighbors_output="$(brain neighbors __cli_contract_focus__.md)"
printf "%s\n" "$neighbors_output" | grep -F "__cli_contract_out__.md" >/dev/null || {
    echo "[FAIL] brain neighbors missing outgoing neighbor"
    echo "$neighbors_output"
    exit 1
}
printf "%s\n" "$neighbors_output" | grep -F "__cli_contract_in__.md" >/dev/null || {
    echo "[FAIL] brain neighbors missing incoming neighbor"
    echo "$neighbors_output"
    exit 1
}
echo "[PASS] brain neighbors CLI contract works"

related_output="$(brain related __cli_contract_focus__.md)"
printf "%s\n" "$related_output" | grep -F "__cli_contract_out__.md" >/dev/null || {
    echo "[FAIL] brain related missing outgoing related note"
    echo "$related_output"
    exit 1
}
printf "%s\n" "$related_output" | grep -F "__cli_contract_in__.md" >/dev/null || {
    echo "[FAIL] brain related missing incoming related note"
    echo "$related_output"
    exit 1
}
echo "[PASS] brain related CLI contract works"

path_output="$(brain path __cli_contract_focus__.md __cli_contract_path_end__.md)"
printf "%s\n" "$path_output" | grep -F "__cli_contract_focus__.md" >/dev/null || {
    echo "[FAIL] brain path missing source note"
    echo "$path_output"
    exit 1
}
printf "%s\n" "$path_output" | grep -F "__cli_contract_path_mid__.md" >/dev/null || {
    echo "[FAIL] brain path missing middle note"
    echo "$path_output"
    exit 1
}
printf "%s\n" "$path_output" | grep -F "__cli_contract_path_end__.md" >/dev/null || {
    echo "[FAIL] brain path missing destination note"
    echo "$path_output"
    exit 1
}
echo "[PASS] brain path CLI contract works"

# ----------------------------------------------------------
# Cognition-facing success contract
# ----------------------------------------------------------
think_output="$(brain think sharedcontractterm)"
printf "%s\n" "$think_output" | grep -F "__cli_contract_out__.md" >/dev/null || {
    echo "[FAIL] brain think missing linked result"
    echo "$think_output"
    exit 1
}
printf "%s\n" "$think_output" | grep -F "__cli_contract_path_mid__.md" >/dev/null || {
    echo "[FAIL] brain think missing path result"
    echo "$think_output"
    exit 1
}
printf "%s\n" "$think_output" | grep -F "__cli_contract_path_end__.md" >/dev/null || {
    echo "[FAIL] brain think missing far path result"
    echo "$think_output"
    exit 1
}
printf "%s\n" "$think_output" | grep -F "__cli_contract_other__.md" >/dev/null || {
    echo "[FAIL] brain think missing unrelated semantic result"
    echo "$think_output"
    exit 1
}
echo "[PASS] brain think CLI contract works"

# ----------------------------------------------------------
# Dispatcher-level ambiguous resolution contract
# ----------------------------------------------------------
trap - ERR
set +e
graph_ambiguous="$(brain graph "__cli_contract_ambiguous__.md" 2>&1)"
graph_status=$?
backlinks_ambiguous="$(brain backlinks "__cli_contract_ambiguous__.md" 2>&1)"
backlinks_status=$?
neighbors_ambiguous="$(brain neighbors "__cli_contract_ambiguous__.md" 2>&1)"
neighbors_status=$?
related_ambiguous="$(brain related "__cli_contract_ambiguous__.md" 2>&1)"
related_status=$?
path_ambiguous="$(brain path "__cli_contract_ambiguous__.md" __cli_contract_path_end__.md 2>&1)"
path_status=$?
set -e
trap on_error ERR

for status_name in \
  graph_status \
  backlinks_status \
  neighbors_status \
  related_status \
  path_status
do
  status_value="${!status_name}"
  [[ "$status_value" -ne 0 ]] || {
      echo "[FAIL] Expected ambiguous CLI command to fail: $status_name"
      exit 1
  }
done

for output_name in \
  graph_ambiguous \
  backlinks_ambiguous \
  neighbors_ambiguous \
  related_ambiguous \
  path_ambiguous
do
  output_value="${!output_name}"

  printf "%s\n" "$output_value" | grep -F "Ambiguous note reference: __cli_contract_ambiguous__.md" >/dev/null || {
      echo "[FAIL] Missing ambiguous error header in $output_name"
      echo "$output_value"
      exit 1
  }

  printf "%s\n" "$output_value" | grep -F "contract-a/__cli_contract_ambiguous__.md" >/dev/null || {
      echo "[FAIL] Missing first ambiguous candidate in $output_name"
      echo "$output_value"
      exit 1
  }

  printf "%s\n" "$output_value" | grep -F "contract-b/__cli_contract_ambiguous__.md" >/dev/null || {
      echo "[FAIL] Missing second ambiguous candidate in $output_name"
      echo "$output_value"
      exit 1
  }
done

echo "[PASS] Ambiguous resolution errors propagate through graph-facing CLI commands"

cleanup

echo "[TEST] Cleanup done"
echo "[SUCCESS] CLI regression contract test completed"
