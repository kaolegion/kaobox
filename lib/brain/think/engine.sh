#!/usr/bin/env bash

[[ -n "${BRAIN_THINK_ENGINE_LOADED:-}" ]] && return 0
readonly BRAIN_THINK_ENGINE_LOADED=1

safe_source "$MODULES_ROOT/memory/query.sh"
safe_source "$KAOBOX_ROOT/lib/brain/context/resolver.sh"

think_engine_run() {

    local query="$1"

    mapfile -t fts_results < <(query_fts "$query" 10)

    for r in "${fts_results[@]}"; do
        echo "$r"
    done
}
