#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Context Scorer
# ----------------------------------------------------------
# Layer: Cognitive
# Responsibility:
#   - Score context candidates
#   - Apply temporal decay
#   - Apply session boost
# ==========================================================
# TODO:
# - Add configuration support
# - Add adaptive learning weights
# - Add telemetry hooks
# ----------------------------------------------------------
# Prevent double load
# ----------------------------------------------------------
[[ -n "${BRAIN_CONTEXT_SCORER_LOADED:-}" ]] && return 0
readonly BRAIN_CONTEXT_SCORER_LOADED=1

# ----------------------------------------------------------
# Load local dependencies (same layer only)
# ----------------------------------------------------------
CONTEXT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CONTEXT_DIR/session.sh"

# ==========================================================
# Function: score_context
# ==========================================================

score_context() {

    declare -A scores
    declare -A last_update

    local now
    now=$(date +%s)

    while IFS="|" read -r path layer updated_at; do
        [[ -z "${path:-}" ]] && continue

        # --------------------------------------------------
        # Base weight per layer
        # --------------------------------------------------
        local base=0
        case "$layer" in
            SELF)      base=4 ;;
            GRAPH_OUT) base=3 ;;
            GRAPH_IN)  base=2 ;;
            RECENT)    base=1 ;;
        esac

        (( base == 0 )) && continue

        local current=${scores["$path"]:-0}
        local decay=100

        # --------------------------------------------------
        # Temporal Decay
        # --------------------------------------------------
        if [[ -n "${updated_at:-}" ]]; then
            local updated
            updated=$(date -d "$updated_at" +%s 2>/dev/null || echo 0)

            if (( updated > 0 )); then
                local age_days=$(( (now - updated) / 86400 ))

                if   (( age_days <= 1 ));  then decay=100
                elif (( age_days <= 7 ));  then decay=70
                elif (( age_days <= 30 )); then decay=40
                else                            decay=20
                fi
            fi
        fi

        local weighted=$(( base * decay / 100 ))

        scores["$path"]=$(( current + weighted ))
        last_update["$path"]="$updated_at"

    done

    # ------------------------------------------------------
    # Session Boost
    # ------------------------------------------------------
    local active
    active=$(session_get_active || true)

    for path in "${!scores[@]}"; do
        local total=${scores[$path]}

        if [[ -n "${active:-}" && "$path" == "$active" ]]; then
            total=$(( total + 5 ))
        fi

        printf "%s|%s\n" "$total" "$path"
    done | sort -t'|' -nr
}
