#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# KAOBOX MEMORY MODULE TEST
# Transactional Index Validation
# ==========================================

trap 'echo "[FAIL] Unexpected error"; rm -f "$TEST_FILE" "$TARGET_FILE"' ERR

echo "[TEST] Starting memory index test"

: "${BRAIN_ROOT:=/data/brain}"

BRAIN_DB="$BRAIN_ROOT/.index/brain.db"
TEST_FILE="$BRAIN_ROOT/notes/__test_memory__.md"
TARGET_FILE="$BRAIN_ROOT/notes/__test_target__.md"

[[ -f "$BRAIN_DB" ]] || {
    echo "[FAIL] Database not found: $BRAIN_DB"
    exit 1
}

mkdir -p "$(dirname "$TEST_FILE")"

# ------------------------------------------
# Create target note
# ------------------------------------------

cat > "$TARGET_FILE" <<'EOF'
# test target

Tags: #target

Target note for graph validation.
EOF

# ------------------------------------------
# Create test note with tags + link
# ------------------------------------------

cat > "$TEST_FILE" <<'EOF'
# Test Memory Module

Tags: #alpha #beta

This is a test note for index validation.

Link:
[[__test_target__.md]]
EOF

echo "[TEST] Test notes created"

# ------------------------------------------
# Reindex
# ------------------------------------------

brain reindex >/dev/null
echo "[TEST] Reindex executed"

SAFE_TEST_PATH="$(printf "%s" "$TEST_FILE" | sed "s/'/''/g")"

# ------------------------------------------
# Validate note insertion
# ------------------------------------------

NOTE_EXISTS="$(
    sqlite3 "$BRAIN_DB" \
        "SELECT COUNT(*) FROM notes WHERE path = '$SAFE_TEST_PATH';"
)"

if [[ "$NOTE_EXISTS" != "1" ]]; then
    echo "[FAIL] Note not inserted correctly"
    exit 1
fi

echo "[PASS] Note inserted"

# ------------------------------------------
# Validate tag linkage
# ------------------------------------------

TAG_COUNT="$(
    sqlite3 "$BRAIN_DB" "
    SELECT COUNT(*)
    FROM tags t
    JOIN note_tags nt ON t.id = nt.tag_id
    JOIN notes n ON nt.note_id = n.id
    WHERE n.path = '$SAFE_TEST_PATH';
    "
)"

if [[ "$TAG_COUNT" != "2" ]]; then
    echo "[FAIL] Tags not linked correctly"
    exit 1
fi

echo "[PASS] Tags linked"

# ------------------------------------------
# Validate graph linkage
# ------------------------------------------

LINK_COUNT="$(
    sqlite3 "$BRAIN_DB" "
    SELECT COUNT(*)
    FROM links l
    JOIN notes src ON src.id = l.source_id
    WHERE src.path = '$SAFE_TEST_PATH';
    "
)"

if [[ "$LINK_COUNT" != "1" ]]; then
    echo "[FAIL] Link not indexed correctly"
    exit 1
fi

echo "[PASS] Link indexed"

# ------------------------------------------
# Cleanup through normal system path
# ------------------------------------------

rm -f "$TEST_FILE" "$TARGET_FILE"
brain reindex >/dev/null

echo "[TEST] Cleanup done"
echo "[SUCCESS] Memory index test completed"
