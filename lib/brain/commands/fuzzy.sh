#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Fuzzy Command
# ==========================================================

cmd_fuzzy() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[ERROR] BRAIN_DB not defined"
        return 1
    }

    command -v fzf >/dev/null 2>&1 || {
        echo "[ERROR] fzf not installed"
        return 1
    }

    local selected
    selected=$(
        sqlite3 -separator "|" "$BRAIN_DB" "
        SELECT n.id,
               n.title,
               n.updated_at,
               IFNULL((
                   SELECT GROUP_CONCAT('#' || t2.name, ' ')
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
        " | while IFS="|" read -r id title date tags; do
            printf "%s|%-30s | %s | %s\n" "$id" "$title" "$date" "$tags"
        done | fzf \
            --delimiter="|" \
            --layout=reverse \
            --height=90% \
            --border \
            --prompt="🧠 Brain > "
    )

    [[ -z "$selected" ]] && return 0

    local note_id
    note_id=$(echo "$selected" | cut -d'|' -f1)

    # Validate numeric id
    [[ "$note_id" =~ ^[0-9]+$ ]] || {
        echo "[ERROR] Invalid selection"
        return 1
    }

    local filepath
    filepath=$(sqlite3 "$BRAIN_DB" "
        SELECT path FROM notes WHERE id=$note_id LIMIT 1;
    ")

    if [[ -z "$filepath" || ! -f "$filepath" ]]; then
        echo "[ERROR] File missing on disk."
        return 1
    fi

    "${EDITOR:-micro}" "$filepath"
}
