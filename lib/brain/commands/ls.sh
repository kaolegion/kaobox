cmd_ls() {
    local query
    query="
        SELECT n.id,
               n.title,
               n.updated_at,
               IFNULL(GROUP_CONCAT(t.name, ','), '')
        FROM notes n
        LEFT JOIN note_tags nt ON n.id = nt.note_id
        LEFT JOIN tags t ON t.id = nt.tag_id
        GROUP BY n.id
        ORDER BY n.updated_at DESC;
    "

    while IFS=$'\t' read -r id title date tags; do
        printf "\n%s\n" "$title"
        printf "Date: %s\n" "$date"
        [ -n "$tags" ] && printf "Tags: %s\n" "$tags"
        printf "%s\n" "----------------------------------------"
    done < <(
        sqlite3 -separator $'\t' "$BRAIN_DB" "$query"
    )
}
