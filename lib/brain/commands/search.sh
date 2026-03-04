cmd_search() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[ERROR] BRAIN_DB not defined"
        return 1
    }

    if [[ $# -lt 1 ]]; then
        usage
        return 1
    fi

    local raw_query="$1"
    log "Search query: $raw_query"

    # ---------------------------------
    # TAG SEARCH
    # ---------------------------------

    if [[ "$raw_query" == tag:* ]]; then
        local raw_tag="${raw_query#tag:}"
        local tag_safe
		tag_safe="$(sanitize_sql "$raw_tag")"

        if [[ -z "$tag_safe" ]]; then
            echo "Empty tag."
            return 1
        fi

        local count=0

        while IFS=$'\t' read -r id title; do
            count=$((count+1))
            printf "%s\n" "$title"
        done < <(
            sqlite3 -separator $'\t' "$BRAIN_DB" "
            SELECT notes.id, notes.title
            FROM notes
            JOIN note_tags ON notes.id = note_tags.note_id
            JOIN tags ON tags.id = note_tags.tag_id
            WHERE tags.name = '$tag_safe'
            ORDER BY notes.updated_at DESC;
            "
        )

        [[ $count -eq 0 ]] && echo "No notes found for tag: $raw_tag"
        return 0
    fi

    # ---------------------------------
    # FTS SEARCH
    # ---------------------------------

    local fts_safe
	fts_safe="$(sanitize_fts "$raw_query")"

    if [[ -z "$fts_safe" ]]; then
        echo "Invalid search query."
        return 1
    fi

    local count=0

    while IFS=$'\t' read -r id title; do
        count=$((count+1))
        printf "%s\n" "$title"
    done < <(
        sqlite3 -separator $'\t' "$BRAIN_DB" "
        SELECT rowid, title
        FROM notes_fts
        WHERE notes_fts MATCH '$fts_safe'
        ORDER BY bm25(notes_fts);
        "
    )

    [[ $count -eq 0 ]] && echo "No results found."
}
