#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Explain Command
# ==========================================================

cmd_explain() {

    local query="$*"

    [[ -z "$query" ]] && {
        log_error "Usage: brain explain <query>"
        return 1
    }

    [[ -f "$BRAIN_DB" ]] || {
        log_error "Brain DB not found: $BRAIN_DB"
        return 1
    }

    log_info "Explaining query: $query"

    echo
    echo "----------------------------------"
    echo "Query : $query"
    echo "----------------------------------"

    sqlite3 "$BRAIN_DB" "
        SELECT
            notes.path,
            bm25(notes_fts) as score
        FROM notes_fts
        JOIN notes ON notes_fts.rowid = notes.id
        WHERE notes_fts MATCH '$query'
        ORDER BY score
        LIMIT 5;
    " | while IFS="|" read -r path score
    do

        echo
        echo "Path      : $path"
        echo "FTS score : $score"

    done

    echo
}
