#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Graph Command
# ----------------------------------------------------------
# Shows outgoing links and backlinks for a note
# - Read-only
# - Deterministic
# ==========================================================

cmd_graph() {

    local query="${1:-}"

    [[ -z "$query" ]] && {
        log_error "Usage: brain graph <note>"
        return 1
    }

    [[ -n "${BRAIN_DB:-}" ]] || {
        log_error "BRAIN_DB not defined"
        return 1
    }

    [[ -f "$BRAIN_DB" ]] || {
        log_error "Brain DB not found: $BRAIN_DB"
        return 1
    }

    log_info "Resolving graph for: $query"

    local safe_query
    safe_query="$(printf "%s" "$query" | sed "s/'/''/g")"

    local note_id
    note_id="$(
        sqlite3 -batch -noheader "$BRAIN_DB" \
            "SELECT id
             FROM notes
             WHERE path  LIKE '%' || '$safe_query' || '%'
                OR title LIKE '%' || '$safe_query' || '%'
             ORDER BY updated_at DESC
             LIMIT 1;"
    )"

    [[ -z "${note_id:-}" ]] && {
        log_error "Note not found."
        return 1
    }

    echo
    echo "----------------------------------"
    echo "Outgoing links"
    echo "----------------------------------"

    sqlite3 -batch -noheader "$BRAIN_DB" "
        SELECT path
        FROM notes
        WHERE id IN (
            SELECT target_id
            FROM links
            WHERE source_id = $note_id
        )
        ORDER BY path;
    "

    echo
    echo "----------------------------------"
    echo "Backlinks"
    echo "----------------------------------"

    sqlite3 -batch -noheader "$BRAIN_DB" "
        SELECT path
        FROM notes
        WHERE id IN (
            SELECT source_id
            FROM links
            WHERE target_id = $note_id
        )
        ORDER BY path;
    "

    echo
}
