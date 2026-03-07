#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Engine Links Layer
# ----------------------------------------------------------
# Emits SQL statements
# Requires active transaction
# Uses note IDs
# ==========================================================

# ----------------------------------------------------------
# Extract [[links]] from markdown
# ----------------------------------------------------------
extract_links() {

    local file="$1"

    [[ -f "$file" ]] || return 0

    grep -oE '\[\[[^]]+\]\]' "$file" 2>/dev/null \
        | sed -E 's/\[\[//; s/\]\]//' \
        | sed -E 's/\|.*//' \
        | sed -E 's/#.*//' \
        | tr '[:upper:]' '[:lower:]'
}

# ----------------------------------------------------------
# Emit SQL to index links
# ----------------------------------------------------------
links_sql() {

    local path="$1"
    local file="$2"

    local source_id
    source_id="(SELECT id FROM notes WHERE path='$(sql_escape "$path")')"

    # Remove existing outgoing links for this source note
    echo "DELETE FROM links WHERE source_id = $source_id;"

    local target
    while IFS= read -r target; do
        [[ -z "${target:-}" ]] && continue

        target="$(sql_escape "$target")"

        cat <<SQL
INSERT INTO links(source_id, target_id)
SELECT
    $source_id,
    id
FROM notes
WHERE title='$target';
SQL

    done < <(extract_links "$file")
}
