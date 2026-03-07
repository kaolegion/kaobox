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

    local query="$1"

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

    mapfile -t fts_results < <(query_fts "$query" 10)

    [[ ${#fts_results[@]} -eq 0 ]] && {
        echo "No results."
        return 0
    }

    # ------------------------------------------------------
    # Ranking (cognitive layer)
    # ------------------------------------------------------

    think_rank_results "$active_focus" "${fts_results[@]}" \
    | while IFS='|' read -r composite raw; do
        echo "$raw"
      done
}
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
