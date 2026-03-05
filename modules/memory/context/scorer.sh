#!/usr/bin/env bash
# ==========================================================
# Context Scorer (Adaptive Ready)
# ==========================================================

source "$MODULES_ROOT/memory/context/session.sh"

score_context() {

    declare -A scores
    declare -A last_update

    now=$(date +%s)

    while IFS="|" read -r path layer updated_at; do
        [[ -z "${path:-}" ]] && continue

        # Base weight per layer
        case "$layer" in
            SELF)      base=4 ;;
            GRAPH_OUT) base=3 ;;
            GRAPH_IN)  base=2 ;;
            RECENT)    base=1 ;;
            *)         base=0 ;;
        esac

        # Skip if no weight
        (( base == 0 )) && continue

        # Initialize if needed
        current=${scores["$path"]:-0}

        # --- Temporal Decay ---
        decay=100

        if [[ -n "${updated_at:-}" ]]; then
            updated=$(date -d "$updated_at" +%s 2>/dev/null || echo 0)

            if (( updated > 0 )); then
                age_days=$(( (now - updated) / 86400 ))

                if (( age_days <= 1 )); then
                    decay=100
                elif (( age_days <= 7 )); then
                    decay=70
                elif (( age_days <= 30 )); then
                    decay=40
                else
                    decay=20
                fi
            fi
        fi

        weighted=$(( base * decay / 100 ))

        scores["$path"]=$(( current + weighted ))
        last_update["$path"]="$updated_at"

    done

    active=$(session_get_active || true)

    for path in "${!scores[@]}"; do
        total=${scores[$path]}

        # --- Session Boost ---
        if [[ -n "${active:-}" && "$path" == "$active" ]]; then
            total=$(( total + 5 ))
        fi

        printf "%s|%s\n" "$total" "$path"
    done | sort -t'|' -nr
}
