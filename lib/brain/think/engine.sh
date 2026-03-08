#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Think Engine
# Orchestration Layer v1.2
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

_load_graph_paths_from_focus() {
    local focus_path="${1:-}"
    local focus_id=""

    [[ -n "${focus_path:-}" ]] || return 0

    focus_id="$(_resolve_focus_note_id "$focus_path")"

    [[ -n "${focus_id:-}" ]] || return 0

    query_graph_proximity_by_note "$focus_id" | awk -F'\t' '{print $2}'
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
    local graph_paths=""
    graph_paths="$(_load_graph_paths_from_focus "$active_focus")"

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
    THINK_GRAPH_PATHS="$graph_paths" \
    think_rank_results "$active_focus" "${fts_results[@]}" \
        | while IFS='|' read -r _ raw; do
            [[ -n "${raw:-}" ]] && echo "$raw"
        done
}
