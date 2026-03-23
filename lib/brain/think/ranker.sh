#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Think Ranker
# Composite Scoring v1.7
# ----------------------------------------------------------
# Score model:
#   composite = relevance + focus_boost + graph_boost + heat_boost + thermal_graph_boost
#
# Input line format (expected):
#   id<TAB>path<TAB>title<TAB>raw_score
#
# Notes:
#   - raw FTS bm25 score is typically negative
#   - relevance is normalized as positive: -1 * raw_score
#   - THINK_GRAPH_PATHS keeps direct binary compatibility
#   - THINK_GRAPH_CONTEXT enables path-aware distance scoring
#   - heat is optional and extracted from projected note metadata
#   - thermal_graph_boost is weak graph propagation from focus heat
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
: "${THINK_HEAT_ENABLED:=1}"
: "${THINK_HEAT_CAP:=3}"
: "${THINK_HEAT_FACTOR:=0.5}"
: "${THINK_THERMAL_GRAPH_FACTOR:=0.5}"

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

graph_distance_for_context_path() {
    local candidate_path="${1:-}"
    local graph_context="${2:-}"
    local path=""
    local distance=""

    [[ -n "$candidate_path" ]] || {
        printf "\n"
        return 0
    }

    [[ -n "$graph_context" ]] || {
        printf "\n"
        return 0
    }

    while IFS=$'\t' read -r _ path _ distance; do
        [[ -n "${path:-}" ]] || continue

        if [[ "$path" == "$candidate_path" ]]; then
            printf "%s\n" "$distance"
            return 0
        fi
    done <<< "$graph_context"

    printf "\n"
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

_extract_note_heat() {
    local note_path="${1:-}"
    local heat="0"

    [[ "${THINK_HEAT_ENABLED:-1}" == "1" ]] || {
        printf "0\n"
        return 0
    }

    [[ -n "${note_path:-}" && -f "$note_path" ]] || {
        printf "0\n"
        return 0
    }

    heat="$(grep -E '^Heat:[[:space:]]*[0-9]+' "$note_path" 2>/dev/null | head -n1 | sed -E 's/^Heat:[[:space:]]*([0-9]+).*$/\1/' || true)"

    if [[ -z "${heat:-}" ]]; then
        heat="$(grep -Eo '#heat-[0-9]+' "$note_path" 2>/dev/null | head -n1 | sed -E 's/^#heat-([0-9]+)$/\1/' || true)"
    fi

    [[ -n "${heat:-}" && "$heat" =~ ^[0-9]+$ ]] || heat="0"
    printf "%s\n" "$heat"
}

_compute_heat_boost() {
    local heat="${1:-0}"

    [[ "$heat" =~ ^[0-9]+([.][0-9]+)?$ ]] || heat="0"

    awk -v h="$heat" '
        BEGIN {
            boost = log(1 + h)
            if (boost < 0) boost = 0
            print boost
        }
    '
}

_compute_thermal_graph_boost() {
    local source_heat="${1:-0}"
    local distance="${2:-}"

    [[ "$source_heat" =~ ^[0-9]+([.][0-9]+)?$ ]] || source_heat="0"
    [[ "$distance" =~ ^[0-9]+$ ]] || {
        printf "0\n"
        return 0
    }

    (( distance >= 1 )) || {
        printf "0\n"
        return 0
    }

    awk -v h="$source_heat" -v d="$distance" -v k="${THINK_THERMAL_GRAPH_FACTOR:-0.5}" '
        BEGIN {
            boost = (k * log(1 + h)) / d
            if (boost < 0) boost = 0
            print boost
        }
    '
}

think_score_components() {
    local focus="${1:-}"
    local line="${2:-}"
    local id=""
    local path=""
    local title=""
    local raw_score=""
    local relevance=""
    local focus_boost="0"
    local graph_boost="0"
    local heat="0"
    local heat_boost="0"
    local thermal_graph_boost="0"
    local composite=""
    local graph_distance=""
    local source_heat="0"

    [[ -n "${line:-}" ]] || return 1

    IFS=$'\t' read -r id path title raw_score <<< "$line"
    [[ -n "${path:-}" && -n "${raw_score:-}" ]] || return 1

    relevance="$(awk "BEGIN { print -1 * ($raw_score) }")"

    if [[ -n "${focus:-}" && "$path" == "$focus" ]]; then
        focus_boost="$THINK_FOCUS_BOOST"
    fi

    if [[ -n "${THINK_GRAPH_CONTEXT:-}" ]]; then
        graph_boost="$(graph_boost_for_context_path "$path" "$THINK_GRAPH_CONTEXT")"
        graph_distance="$(graph_distance_for_context_path "$path" "$THINK_GRAPH_CONTEXT")"
    else
        graph_boost="$(graph_boost_for_path "$path" "$THINK_GRAPH_PATHS")"
        graph_distance="-"
    fi

    heat="$(_extract_note_heat "$path")"
    heat_boost="$(_compute_heat_boost "$heat")"

    if [[ -n "${focus:-}" ]]; then
        source_heat="$(_extract_note_heat "$focus")"
    fi

    thermal_graph_boost="$(_compute_thermal_graph_boost "$source_heat" "$graph_distance")"

    composite="$(awk "BEGIN { print ($relevance) + ($focus_boost) + ($graph_boost) + ($heat_boost) + ($thermal_graph_boost) }")"

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$composite" \
        "$id" \
        "$path" \
        "$title" \
        "$raw_score" \
        "$relevance" \
        "$focus_boost" \
        "$graph_boost" \
        "$graph_distance" \
        "$heat" \
        "$heat_boost" \
        "$thermal_graph_boost"
}

think_rank_results() {
    local focus="${1:-}"
    shift || true

    local results=("$@")
    local line=""
    local scored=""

    for line in "${results[@]}"; do
        [[ -n "${line:-}" ]] || continue

        scored="$(think_score_components "$focus" "$line" || true)"
        [[ -n "${scored:-}" ]] || continue

        printf "%s\n" "$scored"
    done \
        | sort -t$'\t' -k1,1nr -k3,3 \
        | awk -F'\t' 'BEGIN{OFS="\t"} {print $2,$3,$4,$1}'
}

think_rank_results_trace() {
    local focus="${1:-}"
    shift || true

    local results=("$@")
    local line=""
    local scored=""

    for line in "${results[@]}"; do
        [[ -n "${line:-}" ]] || continue

        scored="$(think_score_components "$focus" "$line" || true)"
        [[ -n "${scored:-}" ]] || continue

        printf "%s\n" "$scored"
    done | sort -t$'\t' -k1,1nr -k3,3
}

# ----------------------------------------------------------
# Rekon TODO / alert surface
# ----------------------------------------------------------
# TODO(REKON): add optional cache for repeated focus heat reads if result sets grow
# TODO(REKON): validate thermal graph propagation on real linked hot focus notes
# TODO(REKON): evaluate multi-source propagation only after field validation
# TODO(REKON): add explicit telemetry hook for thermal_graph_boost distribution
