#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Engine Tags Layer (v2.5 Simple)
# ----------------------------------------------------------
# Emits SQL only.
# Uses SELECT id internally.
# Must run inside active transaction.
# ==========================================================

source "$(dirname "$0")/utils.sh"

# Extract hashtags: #tag
extract_tags() {
    grep -oE '#[A-Za-z0-9_-]+' "$1" \
        | sed 's/^#//' \
        | sort -u
}

tags_sql() {
    local path="$1"
    local file="$2"

    local note_id="(SELECT id FROM notes WHERE path='$(sql_escape "$path")')"

    # Clear previous tag relations
    echo "DELETE FROM note_tags WHERE note_id = $note_id;"

    while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue

        cat <<SQL
-- Ensure tag exists
INSERT OR IGNORE INTO tags(name)
VALUES ('$(sql_escape "$tag")');

-- Link tag to note
INSERT OR IGNORE INTO note_tags(note_id, tag_id)
VALUES (
    $note_id,
    (SELECT id FROM tags WHERE name='$(sql_escape "$tag")')
);
SQL
    done < <(extract_tags "$file")
}
