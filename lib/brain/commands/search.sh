cmd_search() {

    [ $# -lt 1 ] && usage

    raw_query="$1"
    log "Search query: $raw_query"

    if [[ "$raw_query" == tag:* ]]; then
        raw_tag="${raw_query#tag:}"
        tag_safe=$(sanitize_sql "$raw_tag")

        [ -z "$tag_safe" ] && { echo "Empty tag."; exit 1; }

        sqlite3 "$BRAIN_DB" "
        SELECT notes.id, notes.title
        FROM notes
        JOIN note_tags ON notes.id = note_tags.note_id
        JOIN tags ON tags.id = note_tags.tag_id
        WHERE tags.name = '$tag_safe';
        "
        return
    fi

    fts_safe=$(sanitize_fts "$raw_query")
    fts_safe=$(sanitize_sql "$fts_safe")

    [ -z "$fts_safe" ] && { echo "Invalid search query."; exit 1; }

    sqlite3 "$BRAIN_DB" "
    SELECT DISTINCT rowid, title
    FROM notes_fts
    WHERE notes_fts MATCH '$fts_safe'
    ORDER BY rank;
    "
}
