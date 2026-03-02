#!/usr/bin/env bash

# ==========================================
# KAOBOX BRAIN INDEXER
# Safe / Idempotent / Production ready
# ==========================================

set -e

BRAIN_DB="/data/brain/.index/brain.db"
FILE="$2"

if [ "$1" != "index" ] || [ -z "$FILE" ]; then
    echo "Usage: index.sh index <file>"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi

TITLE=$(basename "$FILE")
CONTENT=$(sed "s/'/''/g" "$FILE")

# Extract structured tags from "Tags:" line only
TAGS=$(grep -i '^Tags:' "$FILE" \
    | sed 's/^Tags:[[:space:]]*//' \
    | grep -o '#[a-zA-Z0-9_-]\+' \
    | sed 's/#//' \
    | sort -u)

SQL=$(cat <<EOSQL
INSERT INTO notes (title, path, updated_at)
VALUES ('$TITLE', '$FILE', datetime('now'))
ON CONFLICT(path) DO UPDATE SET
  title=excluded.title,
  updated_at=datetime('now');

DELETE FROM note_tags
WHERE note_id = (SELECT id FROM notes WHERE path='$FILE');

DELETE FROM notes_fts
WHERE rowid = (SELECT id FROM notes WHERE path='$FILE');

INSERT INTO notes_fts(rowid, title, content)
SELECT id, title, '$CONTENT'
FROM notes
WHERE path='$FILE';
EOSQL
)

sqlite3 "$BRAIN_DB" "$SQL"


# Insert tags safely
NOTE_ID=$(sqlite3 "$BRAIN_DB" "SELECT id FROM notes WHERE path='$FILE';")

for tag in $TAGS; do
    sqlite3 "$BRAIN_DB" "
    INSERT INTO tags(name)
    VALUES ('$tag')
    ON CONFLICT(name) DO NOTHING;
    "

    TAG_ID=$(sqlite3 "$BRAIN_DB" "SELECT id FROM tags WHERE name='$tag';")

    sqlite3 "$BRAIN_DB" "
    INSERT INTO note_tags(note_id, tag_id)
    VALUES ($NOTE_ID, $TAG_ID)
    ON CONFLICT(note_id, tag_id) DO NOTHING;
    "
done

echo "[Memory] Indexed: $FILE"
