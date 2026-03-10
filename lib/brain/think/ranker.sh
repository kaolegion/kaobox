#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Think Ranker
# Composite Scoring v1.4
# ----------------------------------------------------------
# Score model:
#   composite = relevance + focus_boost + graph_boost
#
# Input line format (expected):
#   id<TAB>path<TAB>title<TAB>raw_score
#
# Notes:
#   - raw FTS bm25 score is typically negative
#   - relevance is normalized as positive: -1 * raw_score
#   - THINK_GRAPH_PATHS keeps direct binary compatibility
#   - THINK_GRAPH_CONTEXT enables path-aware distance scoring
# ==========================================================

[[ -n "${BRAIN_THINK_RANKER_LOADED:-}" ]] && return 0
readonly BRAIN_THINK_RANKER_LOADED=1

# ----------------------------------------------------------
# Configurable weights
# ----------------------------------------------------------
: "${THINK_FOCUS_BOOST:=5}"
: "${THINK_GRAPH_BOOST:=2}"
: "${THINK_GRAPH_PATHS:=}"
: "${THINK_GRAPH_CONTEXT:=}"

# ==========================================================
# Helpers
# ==========================================================

_extract_path() {
    local line="${1:-}"
    local path=""

    IFS=$'\t' read -r _ path _ <<< "$line"

    if [[ -n "$path" ]]; then
        printf "%s\n" "$path"
        return 0
    fi

    printf "%s\n" "$line" | awk '{print $2}'
}

_extract_score() {
    local line="${1:-}"
    local raw_score=""

    IFS=$'\t' read -r _ _ _ raw_score <<< "$line"

    if [[ -n "$raw_score" ]]; then
        printf "%s\n" "$raw_score"
        return 0
    fi

    printf "%s\n" "$line" | awk '{print $NF}'
}

_resolve_graph_boost_weight() {
    local override_value="${BRAIN_THINK_GRAPH_BOOST:-}"

    if [[ -n "$override_value" && "$override_value" =~ ^[0-9]+$ ]]; then
        printf "%s\n" "$override_value"
        return 0
    fi

    printf "%s\n" "$THINK_GRAPH_BOOST"
}

_resolve_graph_boost_for_distance() {
    local distance="${1:-0}"
    local base_weight=""
    local computed=0

    [[ "$distance" =~ ^[0-9]+$ ]] || {
        printf "0\n"
        return 0
    }

    (( distance >= 1 )) || {
        printf "0\n"
        return 0
    }

    base_weight="$(_resolve_graph_boost_weight)"
    computed=$(( base_weight - distance + 1 ))

    if (( computed < 1 )); then
        computed=1
    fi

    printf "%s\n" "$computed"
}

graph_boost_for_path() {
    local candidate_path="${1:-}"
    local graph_paths="${2:-}"
    local resolved_graph_boost=""

    [[ -n "$candidate_path" ]] || {
        printf "0\n"
        return 0
    }

    [[ -n "$graph_paths" ]] || {
        printf "0\n"
        return 0
    }

    resolved_graph_boost="$(_resolve_graph_boost_weight)"

    while IFS= read -r path; do
        [[ -n "$path" ]] || continue

        if [[ "$path" == "$candidate_path" ]]; then
            printf "%s\n" "$resolved_graph_boost"
            return 0
        fi
    done <<< "$graph_paths"

    printf "0\n"
}

graph_boost_for_context_path() {
    local candidate_path="${1:-}"
    local graph_context="${2:-}"
    local path=""
    local distance=""

    [[ -n "$candidate_path" ]] || {
        printf "0\n"
        return 0
    }

    [[ -n "$graph_context" ]] || {
        printf "0\n"
        return 0
    }

    while IFS=$'\t' read -r _ path _ distance; do
        [[ -n "${path:-}" ]] || continue

        if [[ "$path" == "$candidate_path" ]]; then
            _resolve_graph_boost_for_distance "$distance"
            return 0
        fi
    done <<< "$graph_context"

    printf "0\n"
}

# ==========================================================
# Ranking Function
# ==========================================================
# Usage:
#   think_rank_results "<focus_path>" "${results[@]}"
#
# Optional graph context:
#   THINK_GRAPH_PATHS="/path/a.md
#   /path/b.md"
#
#   THINK_GRAPH_CONTEXT="1<TAB>/path/a.md<TAB>Title A<TAB>1
#   2<TAB>/path/b.md<TAB>Title B<TAB>2"
# ==========================================================

think_rank_results() {
    local focus="${1:-}"
    shift || true

    local results=("$@")
    local line=""
    local path=""
    local raw_score=""
    local relevance=""
    local focus_boost=""
    local graph_boost=""
    local composite=""

    for line in "${results[@]}"; do
        [[ -n "${line:-}" ]] || continue

        IFS=$'\t' read -r _ path _ raw_score <<< "$line"

        [[ -n "${path:-}" && -n "${raw_score:-}" ]] || continue

        relevance="$(awk "BEGIN { print -1 * ($raw_score) }")"
        focus_boost="0"
        graph_boost="0"

        if [[ -n "${focus:-}" && "$path" == "$focus" ]]; then
            focus_boost="$THINK_FOCUS_BOOST"
        fi

        if [[ -n "${THINK_GRAPH_CONTEXT:-}" ]]; then
            graph_boost="$(graph_boost_for_context_path "$path" "$THINK_GRAPH_CONTEXT")"
        else
            graph_boost="$(graph_boost_for_path "$path" "$THINK_GRAPH_PATHS")"
        fi

        composite="$(awk "BEGIN { print ($relevance) + ($focus_boost) + ($graph_boost) }")"

        printf "%s|%s\n" "$composite" "$line"
    done | sort -t'|' -k1,1nr -k2,2
}
