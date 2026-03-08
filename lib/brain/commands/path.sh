#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Path Command
# ----------------------------------------------------------
# Finds a graph path between two notes
# - Read-only
# - Deterministic
# - BFS traversal
# ==========================================================

cmd_path() {

    local from_query="${1:-}"
    local to_query="${2:-}"

    [[ -z "$from_query" || -z "$to_query" ]] && {
        log_error "Usage: brain path <from_note> <to_note>"
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

    declare -f query_adjacent_note_ids >/dev/null 2>&1 || {
        log_error "query_adjacent_note_ids not available"
        return 1
    }

    log_info "Resolving path: $from_query -> $to_query"

    local from_resolved to_resolved
    from_resolved="$(resolve_note_ref "$from_query")"
    to_resolved="$(resolve_note_ref "$to_query")"

    [[ -n "${from_resolved:-}" ]] || {
        log_error "Source note not found."
        return 1
    }

    [[ -n "${to_resolved:-}" ]] || {
        log_error "Target note not found."
        return 1
    }

    local from_id from_path from_title from_updated
    local to_id to_path to_title to_updated

    IFS=$'\t' read -r from_id from_path from_title from_updated <<< "$from_resolved"
    IFS=$'\t' read -r to_id to_path to_title to_updated <<< "$to_resolved"

    [[ "$from_id" =~ ^[0-9]+$ ]] || {
        log_error "Invalid source note id"
        return 1
    }

    [[ "$to_id" =~ ^[0-9]+$ ]] || {
        log_error "Invalid target note id"
        return 1
    }

    echo "Path"
    echo "----------------------------------"
    echo "From : ${from_title:-"(untitled)"} | $from_path"
    echo "To   : ${to_title:-"(untitled)"} | $to_path"
    echo

    if [[ "$from_id" == "$to_id" ]]; then
        echo "[0] ${from_title:-"(untitled)"} | $from_path"
        return 0
    fi

    declare -A visited
    declare -A parent_id
    declare -A node_path
    declare -A node_title

    local -a queue=()
    local head=0

    visited["$from_id"]=1
    parent_id["$from_id"]=""
    node_path["$from_id"]="$from_path"
    node_title["$from_id"]="$from_title"
    node_path["$to_id"]="$to_path"
    node_title["$to_id"]="$to_title"

    queue+=("$from_id")

    local found=0
    local current_id next_id next_path next_title row

    while (( head < ${#queue[@]} )); do
        current_id="${queue[$head]}"
        head=$((head + 1))

        while IFS=$'\t' read -r next_id next_path next_title; do
            [[ -z "${next_id:-}" ]] && continue
            [[ "$next_id" =~ ^[0-9]+$ ]] || continue

            if [[ -z "${visited[$next_id]:-}" ]]; then
                visited["$next_id"]=1
                parent_id["$next_id"]="$current_id"
                node_path["$next_id"]="$next_path"
                node_title["$next_id"]="$next_title"
                queue+=("$next_id")

                if [[ "$next_id" == "$to_id" ]]; then
                    found=1
                    break 2
                fi
            fi
        done < <(query_adjacent_note_ids "$current_id")
    done

    if (( found == 0 )); then
        echo "No path found."
        return 0
    fi

    local -a path_ids=()
    local walk_id="$to_id"
    while [[ -n "${walk_id:-}" ]]; do
        path_ids+=("$walk_id")
        walk_id="${parent_id[$walk_id]:-}"
    done

    local idx step=0
    for (( idx=${#path_ids[@]}-1; idx>=0; idx-- )); do
        local id="${path_ids[$idx]}"
        printf "[%s] %s | %s\n" \
            "$step" \
            "${node_title[$id]:-"(untitled)"}" \
            "${node_path[$id]}"
        step=$((step + 1))
    done

    return 0
}
