#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# KAOBOX NOTE REF RESOLUTION TEST
# Phase 3.8.c - Resolver Contract
# ==========================================

cleanup() {
    rm -f \
      "$NOTE_PATH_EXACT" \
      "$NOTE_TITLE_EXACT" \
      "$NOTE_BASENAME_ONLY" \
      "$NOTE_PARTIAL_A" \
      "$NOTE_PARTIAL_B"
    rmdir --ignore-fail-on-non-empty "$BRAIN_ROOT/notes/ref-tests" 2>/dev/null || true
    brain reindex >/dev/null 2>&1 || true
}

on_error() {
    echo "[FAIL] Unexpected error"
    cleanup
    exit 1
}

trap on_error ERR

echo "[TEST] Starting note ref resolution test"

# shellcheck source=/dev/null
source /opt/kaobox/lib/brain/env.sh

NOTE_PATH_EXACT="$BRAIN_ROOT/notes/ref-tests/path-exact.md"
NOTE_TITLE_EXACT="$BRAIN_ROOT/notes/ref-tests/title-exact.md"
NOTE_BASENAME_ONLY="$BRAIN_ROOT/notes/ref-tests/basename-only.md"
NOTE_PARTIAL_A="$BRAIN_ROOT/notes/ref-tests/alpha-related.md"
NOTE_PARTIAL_B="$BRAIN_ROOT/notes/ref-tests/alpha-related-newer.md"

mkdir -p "$BRAIN_ROOT/notes/ref-tests"

cat > "$NOTE_PATH_EXACT" <<'NOTE'
# Path Exact Title

Path exact resolution note.
NOTE

cat > "$NOTE_TITLE_EXACT" <<'NOTE'
# Unique Exact Resolver Title

Title exact resolution note.
NOTE

cat > "$NOTE_BASENAME_ONLY" <<'NOTE'
# Basename Resolver Note

Basename resolution note.
NOTE

cat > "$NOTE_PARTIAL_A" <<'NOTE'
# Alpha Related Old

Partial resolution older note.
NOTE

cat > "$NOTE_PARTIAL_B" <<'NOTE'
# Alpha Related New

Partial resolution newer note.
NOTE

touch -t 202603100101 "$NOTE_PARTIAL_A"
touch -t 202603100202 "$NOTE_PARTIAL_B"

echo "[TEST] Resolver notes created"

brain reindex >/dev/null
echo "[TEST] Reindex executed"

# shellcheck source=/dev/null
source /opt/kaobox/modules/memory/query.sh

result_path="$(resolve_note_ref "$NOTE_PATH_EXACT")"
printf '%s\n' "$result_path" | grep -F $'\t'"$NOTE_PATH_EXACT"$'\t' >/dev/null || {
    echo "[FAIL] Exact path resolution failed"
    exit 1
}
echo "[PASS] Exact path resolution works"

result_path_alias="$(resolve_note_ref 'notes/ref-tests/path-exact.md')"
printf '%s\n' "$result_path_alias" | grep -F $'\t'"$NOTE_PATH_EXACT"$'\t' >/dev/null || {
    echo "[FAIL] Path alias resolution failed"
    exit 1
}
echo "[PASS] Path alias resolution works"

result_title="$(resolve_note_ref 'Unique Exact Resolver Title')"
printf '%s\n' "$result_title" | grep -F $'\t'"$NOTE_TITLE_EXACT"$'\tUnique Exact Resolver Title\t' >/dev/null || {
    echo "[FAIL] Exact title resolution failed"
    exit 1
}
echo "[PASS] Exact title resolution works"

result_basename_md="$(resolve_note_ref 'basename-only.md')"
printf '%s\n' "$result_basename_md" | grep -F $'\t'"$NOTE_BASENAME_ONLY"$'\t' >/dev/null || {
    echo "[FAIL] Basename .md resolution failed"
    exit 1
}
echo "[PASS] Basename .md resolution works"

result_basename_noext="$(resolve_note_ref 'basename-only')"
printf '%s\n' "$result_basename_noext" | grep -F $'\t'"$NOTE_BASENAME_ONLY"$'\t' >/dev/null || {
    echo "[FAIL] Basename without extension resolution failed"
    exit 1
}
echo "[PASS] Basename without extension resolution works"

result_partial="$(resolve_note_ref 'alpha-related')"
printf '%s\n' "$result_partial" | grep -F $'\t'"$NOTE_PARTIAL_A"$'\t' >/dev/null || {
    echo "[FAIL] Partial deterministic fallback failed"
    exit 1
}
echo "[PASS] Partial deterministic fallback works"

cleanup

echo "[TEST] Cleanup done"
echo "[SUCCESS] Note ref resolution test completed"
