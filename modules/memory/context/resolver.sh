#!/usr/bin/env bash
# ==========================================================
# Context Resolver (Safe + Structured)
# ==========================================================

resolve_context() {
    local file="$1"

    [[ -f "${file:-}" ]] || {
        log_error "File not found: $file"
        return 1
    }

    # Escape path
    local safe_file=${file//\'/\'\'}

    local note_id
    note_id=$(sqlite3 "$BRAIN_DB" \
        "SELECT id FROM notes WHERE path='$safe_file';")

    [[ -z "${note_id:-}" ]] && {
        log_warn "Note not indexed: $file"
        return 1
    }

    local SEP="|"

    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT n2.path, 'GRAPH_OUT', n2.updated_at
        FROM links l
        JOIN notes n2 ON l.target_id = n2.id
        WHERE l.source_id = $note_id;
    "

    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT n2.path, 'GRAPH_IN', n2.updated_at
        FROM links l
        JOIN notes n2 ON l.source_id = n2.id
        WHERE l.target_id = $note_id;
    "

    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT path, 'RECENT', updated_at
        FROM notes
        WHERE id != $note_id
        ORDER BY updated_at DESC
        LIMIT 5;
    "

    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT path, 'SELF', updated_at
        FROM notes
        WHERE id = $note_id;
    "
}
