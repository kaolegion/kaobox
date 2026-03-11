#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Graph Command
# ----------------------------------------------------------
# Shows outgoing links and backlinks for a note
# - Read-only
# - Deterministic
# - Delegates graph retrieval to memory query layer
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

    declare -f resolve_note_ref >/dev/null 2>&1 || {
        log_error "resolve_note_ref not available"
        return 1
    }

    declare -f query_outgoing_links >/dev/null 2>&1 || {
        log_error "query_outgoing_links not available"
        return 1
    }

    declare -f query_backlinks_by_note >/dev/null 2>&1 || {
        log_error "query_backlinks_by_note not available"
        return 1
    }

    log_info "Resolving graph for: $query"

    local resolved
    if ! resolved="$(resolve_note_ref "$query" 2>&1)"; then
        log_error "$resolved"
        return 1
    fi

    local note_id note_path note_title note_updated
    IFS=$'\t' read -r note_id note_path note_title note_updated <<< "$resolved"

    [[ "$note_id" =~ ^[0-9]+$ ]] || {
        log_error "Invalid resolved note id"
        return 1
    }

    echo
    echo "Graph"
    echo "----------------------------------"
    echo "Note  : ${note_title:-"(untitled)"}"
    echo "Path  : $note_path"
    echo "ID    : $note_id"

    echo
    echo "----------------------------------"
    echo "Outgoing links"
    echo "----------------------------------"

    local found=0
    while IFS=$'\t' read -r _ path title direction; do
        [[ -z "${path:-}" ]] && continue
        found=1

        if [[ -n "${title:-}" ]]; then
            printf "%s | %s\n" "$title" "$path"
        else
            printf "%s\n" "$path"
        fi
    done < <(query_outgoing_links "$note_id")

    [[ $found -eq 0 ]] && echo "(none)"

    echo
    echo "----------------------------------"
    echo "Backlinks"
    echo "----------------------------------"

    found=0
    while IFS=$'\t' read -r _ path title direction; do
        [[ -z "${path:-}" ]] && continue
        found=1

        if [[ -n "${title:-}" ]]; then
            printf "%s | %s\n" "$title" "$path"
        else
            printf "%s\n" "$path"
        fi
    done < <(query_backlinks_by_note "$note_id")

    if [[ $found -eq 0 ]]; then
        echo "(none)"
    fi

    echo
    return 0
}
