#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Output Renderer
# ----------------------------------------------------------
# - Idempotent
# - CLI Table mode
# - JSON mode
# - Unified formatting layer
# ==========================================================

[[ -n "${BRAIN_RENDERER_LOADED:-}" ]] && return 0
readonly BRAIN_RENDERER_LOADED=1

RENDER_MODE="${RENDER_MODE:-table}"   # table | json | raw

# ----------------------------------------------------------
# Internal: escape JSON
# ----------------------------------------------------------

_json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# ----------------------------------------------------------
# Render Table
# ----------------------------------------------------------

_render_table() {

    local rows=("$@")

    [[ ${#rows[@]} -eq 0 ]] && {
        echo "No results."
        return 0
    }

    printf "%-6s %-30s %s\n" "ID" "TITLE" "PATH"
    printf "%-6s %-30s %s\n" "----" "------------------------------" "---------------------------"

    for row in "${rows[@]}"; do
        IFS=$'\t' read -r id path title score <<< "$row"
        printf "%-6s %-30s %s\n" "$id" "${title:0:28}" "$path"
    done
}

# ----------------------------------------------------------
# Render JSON
# ----------------------------------------------------------

_render_json() {

    local rows=("$@")

    printf "[\n"
    local first=1

    for row in "${rows[@]}"; do
        IFS=$'\t' read -r id path title score <<< "$row"

        [[ $first -eq 0 ]] && printf ",\n"
        first=0

        printf "  {\n"
        printf "    \"id\": \"%s\",\n" "$(_json_escape "$id")"
        printf "    \"path\": \"%s\",\n" "$(_json_escape "$path")"
        printf "    \"title\": \"%s\",\n" "$(_json_escape "$title")"
        printf "    \"score\": \"%s\"\n" "$(_json_escape "${score:-}")"
        printf "  }"
    done

    printf "\n]\n"
}

# ----------------------------------------------------------
# Public API
# ----------------------------------------------------------

render_results() {

    local mode="${1:-$RENDER_MODE}"
    shift || true

    local rows=("$@")

    case "$mode" in
        table)
            _render_table "${rows[@]}"
            ;;
        json)
            _render_json "${rows[@]}"
            ;;
        raw)
            printf "%s\n" "${rows[@]}"
            ;;
        *)
            echo "[Renderer] Unknown mode: $mode"
            return 1
            ;;
    esac
}
