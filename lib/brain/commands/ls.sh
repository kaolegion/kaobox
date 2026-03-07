#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - ls Command
# ==========================================================

cmd_ls() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[ERROR] BRAIN_DB not defined"
        return 1
    }

    local query
    query="
        SELECT n.id,
               n.title,
               n.updated_at,
               IFNULL((
                   SELECT GROUP_CONCAT(name, ',')
                   FROM (
                       SELECT t2.name
                       FROM note_tags nt2
                       JOIN tags t2 ON t2.id = nt2.tag_id
                       WHERE nt2.note_id = n.id
                       ORDER BY t2.name
                   )
               ), '')
        FROM notes n
        ORDER BY n.updated_at DESC;
    "

    local count=0

    while IFS=$'\t' read -r id title date tags; do
        count=$((count+1))
        printf "\n%s\n" "$title"
        printf "Date: %s\n" "$date"
        [[ -n "$tags" ]] && printf "Tags: %s\n" "$tags"
        printf "%s\n" "----------------------------------------"
    done < <(
        sqlite3 -separator $'\t' "$BRAIN_DB" "$query"
    )

    if [[ $count -eq 0 ]]; then
        echo "[Brain] No notes indexed."
    fi
}
