#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Think Ranker (Composite Scoring v1.2 ready)
# ==========================================================

[[ -n "${BRAIN_THINK_RANKER_LOADED:-}" ]] && return 0
readonly BRAIN_THINK_RANKER_LOADED=1

# ----------------------------------------------------------
# Configurable weights
# ----------------------------------------------------------

: "${THINK_FOCUS_BOOST:=5}"

# ==========================================================
# Helpers
# ==========================================================

_extract_path() {
    # Extract second column safely (tab or space separated)
    local line="$1"

    # Try tab first
    local path
    IFS=$'\t' read -r _ path _ <<< "$line"

    if [[ -n "$path" ]]; then
        printf "%s\n" "$path"
        return
    fi

    # Fallback to space parsing
    printf "%s\n" "$line" | awk '{print $2}'
}

_extract_score() {
    # Extract last field (score)
    printf "%s\n" "$1" | awk '{print $NF}'
}

# ==========================================================
# Ranking Function
# ==========================================================

think_rank_results() {

    local focus="$1"
    shift
    local results=("$@")

    local line id path title raw_score relevance composite

    for line in "${results[@]}"; do

        [[ -z "${line:-}" ]] && continue

        # Safe parsing (TAB separated)
        IFS=$'\t' read -r id path title raw_score <<< "$line"

        # Skip malformed lines
        [[ -z "${path:-}" || -z "${raw_score:-}" ]] && continue

        # Normalize FTS score (bm25 negative → positive relevance)
        relevance=$(awk "BEGIN {print -1 * ($raw_score)}")

        composite="$relevance"

        # Focus boost
        if [[ -n "${focus:-}" && "$path" == "$focus" ]]; then
            composite=$(awk "BEGIN {print $relevance + $THINK_FOCUS_BOOST}")
        fi

        printf "%s|%s\n" "$composite" "$line"

    done | sort -t'|' -k1 -nr
}
