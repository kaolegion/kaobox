#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Related Command
# ----------------------------------------------------------
# Shows directly related notes for a note
# - Read-only
# - Deterministic
# - Based on direct graph proximity
# ==========================================================

cmd_related() {

    local query="${1:-}"

    [[ -z "$query" ]] && {
        log_error "Usage: brain related <note>"
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

    declare -f query_graph_proximity_by_note >/dev/null 2>&1 || {
        log_error "query_graph_proximity_by_note not available"
        return 1
    }

    log_info "Resolving related notes for: $query"

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

    echo "Related"
    echo "----------------------------------"
    echo "Note : ${note_title:-"(untitled)"}"
    echo "Path : $note_path"
    echo

    local found=0
    while IFS=$'\t' read -r _ path title distance; do
        [[ -z "${path:-}" ]] && continue
        found=1

        printf "[d=%s] %s" "${distance:-"?"}" "${title:-"(untitled)"}"
        if [[ -n "${path:-}" ]]; then
            printf " | %s" "$path"
        fi
        printf "\n"
    done < <(query_graph_proximity_by_note "$note_id")

    if [[ $found -eq 0 ]]; then
        echo "(none)"
    fi

    return 0
}
