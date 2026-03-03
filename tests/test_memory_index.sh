#!/usr/bin/env bash

# ==========================================
# KAOBOX MEMORY MODULE TEST
# Tests index.sh transactional behavior
# ==========================================

set -e

BRAIN_DB="/data/brain/.index/brain.db"
TEST_FILE="/data/brain/notes/__test_memory__.md"

echo "[TEST] Starting memory index test"

# ------------------------------------------
# Create test note
# ------------------------------------------

cat <<EOF > "$TEST_FILE"
# Test Memory Module

Tags: #alpha #beta

This is a test note for index validation.
EOF

echo "[TEST] Test file created"

# ------------------------------------------
# Run index
# ------------------------------------------

/opt/kaobox/modules/memory/index.sh index "$TEST_FILE"

echo "[TEST] Index executed"

# ------------------------------------------
# Validate note insertion
# ------------------------------------------

NOTE_EXISTS=$(sqlite3 "$BRAIN_DB" \
"SELECT COUNT(*) FROM notes WHERE path='$TEST_FILE';")

if [ "$NOTE_EXISTS" != "1" ]; then
  echo "[FAIL] Note not inserted correctly"
  exit 1
fi

echo "[PASS] Note inserted"

# ------------------------------------------
# Validate tags
# ------------------------------------------

TAG_COUNT=$(sqlite3 "$BRAIN_DB" "
SELECT COUNT(*) 
FROM tags t
JOIN note_tags nt ON t.id = nt.tag_id
JOIN notes n ON nt.note_id = n.id
WHERE n.path='$TEST_FILE';
")

if [ "$TAG_COUNT" != "2" ]; then
  echo "[FAIL] Tags not linked correctly"
  exit 1
fi

echo "[PASS] Tags linked"

# ------------------------------------------
# Cleanup
# ------------------------------------------

sqlite3 "$BRAIN_DB" "DELETE FROM notes WHERE path='$TEST_FILE';"
rm -f "$TEST_FILE"

echo "[TEST] Cleanup done"
echo "[SUCCESS] Memory index test completed"
