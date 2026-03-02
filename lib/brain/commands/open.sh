cmd_open() {

    [ $# -lt 1 ] && usage

    raw_filename="$1"
    filename_safe=$(sanitize_sql "$raw_filename")

    filepath=$(sqlite3 "$BRAIN_DB" "
        SELECT path FROM notes
        WHERE path LIKE '%' || '$filename_safe' || '%'
        LIMIT 1;
    ")

    [ -z "$filepath" ] && { echo "Note not found."; exit 1; }

    ${EDITOR:-micro} "$filepath"
}
