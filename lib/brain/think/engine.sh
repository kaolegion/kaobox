#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Think Engine (Orchestration Layer v1.1)
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
# THINK ENGINE RUNNER
# ==========================================================
think_engine_run() {

    local query="${1:-}"
    [[ -z "$query" ]] && return 0

    # ------------------------------------------------------
    # Active focus (if context available)
    # ------------------------------------------------------
    local active_focus=""
    if declare -f session_get_active >/dev/null 2>&1; then
        active_focus="$(session_get_active 2>/dev/null || true)"
    fi

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
    think_rank_results "$active_focus" "${fts_results[@]}" \
        | while IFS='|' read -r _ raw; do
            [[ -n "${raw:-}" ]] && echo "$raw"
        done
}
