#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Engine Links Layer (v2.5 Simple)
# ----------------------------------------------------------
# Emits SQL only.
# Uses SELECT id internally.
# Must run inside active transaction.
# ==========================================================

source "$(dirname "$0")/utils.sh"

extract_links() {
    grep -oE '\[\[[^]]+\]\]' "$1" \
        | sed 's/\[\[//;s/\]\]//' \
        | sort -u
}

links_sql() {
    local path="$1"
    local file="$2"

    local source_id="(SELECT id FROM notes WHERE path='$(sql_escape "$path")')"

    echo "DELETE FROM links WHERE source_id = $source_id;"

    while IFS= read -r target; do
        [[ -z "$target" ]] && continue

        cat <<SQL
INSERT OR IGNORE INTO links(source_id, target_id)
VALUES (
    $source_id,
    (SELECT id FROM notes WHERE title='$(sql_escape "$target")')
);
SQL
    done < <(extract_links "$file")
}
