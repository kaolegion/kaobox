#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Graph Command
# ==========================================================

cmd_graph() {

    local query="$1"

    [[ -z "$query" ]] && {
        log_error "Usage: brain graph <note>"
        return 1
    }

    [[ -f "$BRAIN_DB" ]] || {
        log_error "Brain DB not found: $BRAIN_DB"
        return 1
    }

    log_info "Resolving graph for: $query"

    local note_id
    note_id=$(sqlite3 "$BRAIN_DB" \
        "SELECT id FROM notes WHERE path LIKE '%$query' LIMIT 1;")

    [[ -z "$note_id" ]] && {
        log_error "Note not found."
        return 1
    }

    echo
    echo "----------------------------------"
    echo "Outgoing links"
    echo "----------------------------------"

    sqlite3 "$BRAIN_DB" "
        SELECT path
        FROM notes
        WHERE id IN (
            SELECT target_id
            FROM links
            WHERE source_id = $note_id
        );
    "

    echo
    echo "----------------------------------"
    echo "Backlinks"
    echo "----------------------------------"

    sqlite3 "$BRAIN_DB" "
        SELECT path
        FROM notes
        WHERE id IN (
            SELECT source_id
            FROM links
            WHERE target_id = $note_id
        );
    "

    echo
}
