#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Context Resolver
# ----------------------------------------------------------
# Layer: Cognitive
# Responsibility:
#   - Retrieve context candidates from memory graph
#   - Output: path|layer|updated_at
# Depends on:
#   - BRAIN_DB
# ==========================================================
# TODO:
# - Add configuration support
# - Add adaptive learning weights
# - Add telemetry hooks
# ----------------------------------------------------------
# Prevent double load
# ----------------------------------------------------------
[[ -n "${BRAIN_CONTEXT_RESOLVER_LOADED:-}" ]] && return 0
readonly BRAIN_CONTEXT_RESOLVER_LOADED=1

# ==========================================================
# Function: resolve_context
# ==========================================================

resolve_context() {

    local file="$1"

    [[ -f "${file:-}" ]] || {
        log_error "[context] File not found: $file"
        return 1
    }

    [[ -n "${BRAIN_DB:-}" && -f "$BRAIN_DB" ]] || {
        log_error "[context] BRAIN_DB not available"
        return 1
    }

    # ------------------------------------------------------
    # Escape path safely
    # ------------------------------------------------------
    local safe_file
    safe_file=${file//\'/\'\'}

    # ------------------------------------------------------
    # Retrieve note ID
    # ------------------------------------------------------
    local note_id
    note_id=$(sqlite3 "$BRAIN_DB" \
        "SELECT id FROM notes WHERE path='$safe_file';")

    [[ -z "${note_id:-}" || ! "$note_id" =~ ^[0-9]+$ ]] && {
        log_warn "[context] Note not indexed: $file"
        return 1
    }

    local SEP="|"

    # ------------------------------------------------------
    # GRAPH_OUT
    # ------------------------------------------------------
    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT n2.path, 'GRAPH_OUT', n2.updated_at
        FROM links l
        JOIN notes n2 ON l.target_id = n2.id
        WHERE l.source_id = $note_id;
    "

    # ------------------------------------------------------
    # GRAPH_IN
    # ------------------------------------------------------
    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT n2.path, 'GRAPH_IN', n2.updated_at
        FROM links l
        JOIN notes n2 ON l.source_id = n2.id
        WHERE l.target_id = $note_id;
    "

    # ------------------------------------------------------
    # RECENT
    # ------------------------------------------------------
    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT path, 'RECENT', updated_at
        FROM notes
        WHERE id != $note_id
        ORDER BY updated_at DESC
        LIMIT 5;
    "

    # ------------------------------------------------------
    # SELF
    # ------------------------------------------------------
    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT path, 'SELF', updated_at
        FROM notes
        WHERE id = $note_id;
    "
}
