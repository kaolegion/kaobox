#!/usr/bin/env bash

# ==========================================
# KAOBOX MEMORY MODULE REINDEX TEST
# Test reindex functionality
# ==========================================

set -e

BRAIN_DB="/data/brain/.index/brain.db"
TEST_FILE="/data/brain/notes/__test_reindex__.md"

echo "[TEST] Starting reindex test"

# ------------------------------------------
# Create test note
# ------------------------------------------

cat <<EOF > "$TEST_FILE"
# Test Reindex Module

Tags: #alpha #reindex

This is a test note to validate reindex functionality.
EOF

echo "[TEST] Test file created"

# ------------------------------------------
# Run index for the new note
# ------------------------------------------

/opt/kaobox/modules/memory/index.sh index "$TEST_FILE"

echo "[TEST] Index executed for new note"

# ------------------------------------------
# Check if note is indexed
# ------------------------------------------

NOTE_EXISTS=$(sqlite3 "$BRAIN_DB" \
"SELECT COUNT(*) FROM notes WHERE path='$TEST_FILE';")

if [ "$NOTE_EXISTS" != "1" ]; then
  echo "[FAIL] Note not indexed correctly"
  exit 1
fi

echo "[PASS] Note indexed"

# ------------------------------------------
# Run reindexing for all notes
# ------------------------------------------

echo "[TEST] Running reindex"

/opt/kaobox/bin/brain reindex

echo "[TEST] Reindex executed"

# ------------------------------------------
# Validate note is still indexed after reindex
# ------------------------------------------

NOTE_EXISTS_AFTER_REINDEX=$(sqlite3 "$BRAIN_DB" \
"SELECT COUNT(*) FROM notes WHERE path='$TEST_FILE';")

if [ "$NOTE_EXISTS_AFTER_REINDEX" != "1" ]; then
  echo "[FAIL] Note not found after reindex"
  exit 1
fi

echo "[PASS] Note still indexed after reindex"

# ------------------------------------------
# Validate tags are still present after reindex
# ------------------------------------------

TAG_COUNT_AFTER_REINDEX=$(sqlite3 "$BRAIN_DB" "
SELECT COUNT(*) 
FROM tags t
JOIN note_tags nt ON t.id = nt.tag_id
JOIN notes n ON nt.note_id = n.id
WHERE n.path='$TEST_FILE';
")

if [ "$TAG_COUNT_AFTER_REINDEX" != "2" ]; then
  echo "[FAIL] Tags not linked after reindex"
  exit 1
fi

echo "[PASS] Tags linked after reindex"

# ------------------------------------------
# Cleanup
# ------------------------------------------

sqlite3 "$BRAIN_DB" "DELETE FROM notes WHERE path='$TEST_FILE';"
rm -f "$TEST_FILE"

echo "[TEST] Cleanup done"
echo "[SUCCESS] Reindex test completed"
