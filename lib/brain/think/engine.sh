#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Think Engine
# Orchestration Layer v1.4
# ----------------------------------------------------------
# Responsibilities:
#   - resolve active cognitive focus
#   - retrieve raw FTS candidates
#   - expand graph context from active focus
#   - pass contextual signals to ranker
#   - emit ranked raw results
# ==========================================================

[[ -n "${BRAIN_THINK_ENGINE_LOADED:-}" ]] && return 0
readonly BRAIN_THINK_ENGINE_LOADED=1

# ----------------------------------------------------------
# Dependencies
# ----------------------------------------------------------
safe_source "$MODULES_ROOT/memory/query.sh"
safe_source "$KAOBOX_ROOT/lib/brain/context/session.sh"
safe_source "$KAOBOX_ROOT/lib/brain/think/ranker.sh"

# ==========================================================
# Helpers
# ==========================================================

_resolve_focus_note_id() {
    local focus_path="${1:-}"
    local resolved=""

    [[ -n "${focus_path:-}" ]] || return 1

    resolved="$(resolve_note_ref "$focus_path" 2>/dev/null || true)"
    [[ -n "${resolved:-}" ]] || return 1

    printf "%s\n" "$resolved" | awk -F'\t' '{print $1}'
}

_load_graph_context_from_focus() {
    local focus_path="${1:-}"
    local focus_id=""

    [[ -n "${focus_path:-}" ]] || return 0

    focus_id="$(_resolve_focus_note_id "$focus_path")"
    [[ -n "${focus_id:-}" ]] || return 0

    query_graph_context_by_note "$focus_id" 3
}

_load_graph_paths_from_context() {
    local graph_context="${1:-}"

    [[ -n "${graph_context:-}" ]] || return 0

    printf "%s\n" "$graph_context" | awk -F'\t' 'NF >= 2 {print $2}'
}

_print_think_trace_header() {
    local query="${1:-}"
    local active_focus="${2:-}"
    local graph_context="${3:-}"
    local fts_count="${4:-0}"
    local graph_count=0

    if [[ -n "${graph_context:-}" ]]; then
        graph_count="$(printf "%s\n" "$graph_context" | awk 'NF > 0 {count++} END {print count+0}')"
    fi

    echo "TRACE THINK"
    echo "----------------------------------------"
    echo "Query              : $query"

    if [[ -n "${active_focus:-}" ]]; then
        echo "Active focus       : $active_focus"
    else
        echo "Active focus       : (none)"
    fi

    echo "Graph boost weight : $(_resolve_graph_boost_weight)"
    echo "FTS result count   : $fts_count"
    echo "Graph context size : $graph_count"
    echo
}

_print_graph_context_trace() {
    local graph_context="${1:-}"

    echo "GRAPH CONTEXT"
    echo "----------------------------------------"

    if [[ -z "${graph_context:-}" ]]; then
        echo "(none)"
        echo
        return 0
    fi

    while IFS=$'\t' read -r _ path title distance; do
        [[ -n "${path:-}" ]] || continue
        printf "[d=%s] %s" "${distance:-"?"}" "${title:-"(untitled)"}"
        printf " | %s\n" "$path"
    done <<< "$graph_context"

    echo
}

_print_ranked_trace() {
    local active_focus="${1:-}"
    shift || true

    local results=("$@")

    echo "RANKED RESULTS"
    echo "----------------------------------------"

    think_rank_results_trace "$active_focus" "${results[@]}" \
        | while IFS=$'\t' read -r composite id path title raw_score relevance focus_boost graph_boost graph_distance; do
            [[ -n "${path:-}" ]] || continue

            echo "Path         : $path"
            echo "Title        : ${title:-"(untitled)"}"
            echo "ID           : $id"
            echo "Raw score    : $raw_score"
            echo "Relevance    : $relevance"
            echo "Focus boost  : $focus_boost"
            echo "Graph boost  : $graph_boost"

            if [[ -n "${graph_distance:-}" ]]; then
                echo "Graph dist   : $graph_distance"
            else
                echo "Graph dist   : -"
            fi

            echo "Composite    : $composite"
            echo
        done
}

# ==========================================================
# THINK ENGINE RUNNER
# ==========================================================
think_engine_run() {
    local query="${1:-}"
    [[ -n "$query" ]] || return 0

    # ------------------------------------------------------
    # Active focus (if context available)
    # ------------------------------------------------------
    local active_focus=""
    if declare -f session_get_active >/dev/null 2>&1; then
        active_focus="$(session_get_active 2>/dev/null || true)"
    fi

    # ------------------------------------------------------
    # Graph context expansion
    # ------------------------------------------------------
    local graph_context=""
    local graph_paths=""

    graph_context="$(_load_graph_context_from_focus "$active_focus")"
    graph_paths="$(_load_graph_paths_from_context "$graph_context")"

    # ------------------------------------------------------
    # FTS retrieval (raw layer)
    # ------------------------------------------------------
    local -a fts_results=()
    mapfile -t fts_results < <(query_fts "$query" 10)

    if [[ ${#fts_results[@]} -eq 0 ]]; then
        echo "No results."
        return 0
    fi

    # ------------------------------------------------------
    # Ranking (cognitive layer)
    # ------------------------------------------------------
    THINK_GRAPH_CONTEXT="$graph_context" \
    THINK_GRAPH_PATHS="$graph_paths" \
    think_rank_results "$active_focus" "${fts_results[@]}"
}

think_engine_trace() {
    local query="${1:-}"
    [[ -n "$query" ]] || return 0

    local active_focus=""
    local graph_context=""
    local graph_paths=""
    local -a fts_results=()

    if declare -f session_get_active >/dev/null 2>&1; then
        active_focus="$(session_get_active 2>/dev/null || true)"
    fi

    graph_context="$(_load_graph_context_from_focus "$active_focus")"
    graph_paths="$(_load_graph_paths_from_context "$graph_context")"

    mapfile -t fts_results < <(query_fts "$query" 10)

    if [[ ${#fts_results[@]} -eq 0 ]]; then
        echo "TRACE THINK"
        echo "----------------------------------------"
        echo "Query              : $query"
        echo "Active focus       : ${active_focus:-"(none)"}"
        echo "Graph boost weight : $(_resolve_graph_boost_weight)"
        echo "FTS result count   : 0"
        echo "Graph context size : 0"
        echo
        echo "No results."
        return 0
    fi

    THINK_GRAPH_CONTEXT="$graph_context" \
    THINK_GRAPH_PATHS="$graph_paths" \
    _print_think_trace_header "$query" "$active_focus" "$graph_context" "${#fts_results[@]}"

    _print_graph_context_trace "$graph_context"

    THINK_GRAPH_CONTEXT="$graph_context" \
    THINK_GRAPH_PATHS="$graph_paths" \
    _print_ranked_trace "$active_focus" "${fts_results[@]}"
}
