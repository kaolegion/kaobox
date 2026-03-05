#!/usr/bin/env bash

# ==========================================
# KAOBOX MEMORY MODULE TEST
# Transactional Index Validation
# ==========================================

set -euo pipefail

trap 'echo "[FAIL] Unexpected error"; rm -f "$TEST_FILE"' ERR

echo "[TEST] Starting memory index test"

# ------------------------------------------
# Resolve runtime paths
# ------------------------------------------

: "${BRAIN_ROOT:=/data/brain}"

BRAIN_DB="$BRAIN_ROOT/.index/brain.db"
TEST_FILE="$BRAIN_ROOT/notes/__test_memory__.md"

# ------------------------------------------
# Preflight checks
# ------------------------------------------

[[ -f "$BRAIN_DB" ]] || {
  echo "[FAIL] Database not found"
  exit 1
}

mkdir -p "$(dirname "$TEST_FILE")"

# ------------------------------------------
# Create test note
# ------------------------------------------

cat > "$TEST_FILE" <<EOF
# Test Memory Module

Tags: #alpha #beta

This is a test note for index validation.
EOF

echo "[TEST] Test file created"

# ------------------------------------------
# Run reindex via CLI (architecture aligned)
# ------------------------------------------

brain reindex

echo "[TEST] Reindex executed"

# ------------------------------------------
# Validate note insertion
# ------------------------------------------

SAFE_PATH=$(printf "%s" "$TEST_FILE" | sed "s/'/''/g")

NOTE_EXISTS=$(sqlite3 "$BRAIN_DB" \
  "SELECT COUNT(*) FROM notes WHERE path = '$SAFE_PATH';")

if [[ "$NOTE_EXISTS" != "1" ]]; then
  echo "[FAIL] Note not inserted correctly"
  exit 1
fi

echo "[PASS] Note inserted"

# ------------------------------------------
# Validate tag linkage
# ------------------------------------------

TAG_COUNT=$(sqlite3 "$BRAIN_DB" "
SELECT COUNT(*)
FROM tags t
JOIN note_tags nt ON t.id = nt.tag_id
JOIN notes n ON nt.note_id = n.id
WHERE n.path = '$SAFE_PATH';
")

if [[ "$TAG_COUNT" != "2" ]]; then
  echo "[FAIL] Tags not linked correctly"
  exit 1
fi

echo "[PASS] Tags linked"

# ------------------------------------------
# Cleanup (transactional)
# ------------------------------------------

sqlite3 "$BRAIN_DB" <<SQL
BEGIN;
DELETE FROM note_tags WHERE note_id IN (
  SELECT id FROM notes WHERE path = '$TEST_FILE'
);
DELETE FROM notes WHERE path = '$TEST_FILE';
COMMIT;
SQL

rm -f "$TEST_FILE"

echo "[TEST] Cleanup done"
echo "[SUCCESS] Memory index test completed"
