#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Open Command
# ==========================================================

cmd_open() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[ERROR] BRAIN_DB not defined"
        return 1
    }

    if [[ $# -lt 1 ]]; then
        usage
        return 1
    fi

    local raw_filename="$1"

    # Escape single quotes safely
    local filename_safe
    filename_safe="$(printf "%s" "$raw_filename" | sed "s/'/''/g")"

    local query="
        SELECT path
        FROM notes
        WHERE path LIKE '%' || '$filename_safe' || '%'
        ORDER BY updated_at DESC
        LIMIT 1;
    "

    local filepath
    filepath=$(sqlite3 "$BRAIN_DB" "$query")

    if [[ -z "$filepath" ]]; then
        echo "Note not found."
        return 1
    fi

    if [[ ! -f "$filepath" ]]; then
        echo "File missing on disk: $filepath"
        return 1
    fi

    "${EDITOR:-micro}" "$filepath"
}
