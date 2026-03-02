cmd_fuzzy() {

    selected=$(
        sqlite3 -separator "|" "$BRAIN_DB" "
        SELECT notes.id, notes.title, notes.updated_at,
        IFNULL(GROUP_CONCAT('#' || tags.name, ' '), '')
        FROM notes
        LEFT JOIN note_tags ON notes.id = note_tags.note_id
        LEFT JOIN tags ON tags.id = note_tags.tag_id
        GROUP BY notes.id
        ORDER BY notes.updated_at DESC;
        " | while IFS="|" read -r id title date tags; do
            printf "%s|%-30s | %s | %s\n" "$id" "$title" "$date" "$tags"
        done | fzf \
            --delimiter="|" \
            --layout=reverse \
            --height=90% \
            --border \
            --prompt="🧠 Brain > "
    )

    [ -z "$selected" ] && exit 0

    note_id=$(echo "$selected" | cut -d'|' -f1)

    filepath=$(sqlite3 "$BRAIN_DB" "
        SELECT path FROM notes WHERE id=$note_id LIMIT 1;
    ")

    ${EDITOR:-micro} "$filepath"
}
