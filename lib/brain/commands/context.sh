#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Context Command Layer
# ----------------------------------------------------------
# Layer: Cognitive (Kernel Extension)
# Depends on: context/{resolver,scorer,session}
# ==========================================================

# ----------------------------------------------------------
# Prevent double load
# ----------------------------------------------------------
[[ -n "${BRAIN_CONTEXT_CMD_LOADED:-}" ]] && return 0
readonly BRAIN_CONTEXT_CMD_LOADED=1

# ----------------------------------------------------------
# Load Context Layer (Kernel level)
# ----------------------------------------------------------
# shellcheck source=/dev/null
source "$KAOBOX_ROOT/lib/brain/context/resolver.sh"
# shellcheck source=/dev/null
source "$KAOBOX_ROOT/lib/brain/context/scorer.sh"
# shellcheck source=/dev/null
source "$KAOBOX_ROOT/lib/brain/context/session.sh"

# ----------------------------------------------------------
# Usage
# ----------------------------------------------------------
_context_usage() {
    log_error "Usage: brain context [--trace] <file>"
}

_focus_usage() {
    log_error "Usage: brain focus <file>"
}

# ==========================================================
# Command: brain context
# ==========================================================
cmd_context() {

    local trace=0
    local file=""

    # ------------------------------------------------------
    # Parse args (deterministic)
    # ------------------------------------------------------
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --trace)
                trace=1
                shift
                ;;
            -h|--help|help)
                _context_usage
                return 0
                ;;
            *)
                # First non-flag = file
                file="$1"
                shift
                ;;
        esac
    done

    [[ -z "${file:-}" ]] && { _context_usage; return 1; }

    [[ -f "$file" ]] || {
        log_error "File not found: $file"
        return 1
    }

    log_info "[context] Resolving for $file"

    # ------------------------------------------------------
    # Resolve once (so trace + score share same candidates)
    # ------------------------------------------------------
    local -a candidates=()
    if ! mapfile -t candidates < <(resolve_context "$file"); then
        # resolve_context already logs errors
        return 1
    fi

    # ------------------------------------------------------
    # Trace mode (observability)
    # ------------------------------------------------------
    if (( trace == 1 )); then
        echo "TRACE CONTEXT"
        echo "----------------------------------------"

        # Active session context
        local active=""
        active="$(session_get_active 2>/dev/null || true)"
        if [[ -n "${active:-}" ]]; then
            echo "Active session: $active"
        else
            echo "Active session: (none)"
        fi
        echo

        # Counts per layer
        echo "Layers:"
        printf "%s\n" "${candidates[@]}" \
            | awk -F'|' 'NF>=2 {cnt[$2]++} END {for (k in cnt) printf "  %s: %d\n", k, cnt[k]}' \
            | sort
        echo

        # Show first candidates (bounded)
        echo "Candidates (first 50):"
        printf "%s\n" "${candidates[@]}" \
            | awk -F'|' 'NF>=3 {printf "  %s | %s | %s\n", $2, $1, $3}' \
            | head -50
        echo

        echo "Scored top:"
        echo "----------------------------------------"
    fi

    # ------------------------------------------------------
    # Score + output (top 10)
    # ------------------------------------------------------
    set -o pipefail

    printf "%s\n" "${candidates[@]}" \
        | score_context \
        | head -10 \
        | while IFS="|" read -r score path; do
            [[ -z "${score:-}" || -z "${path:-}" ]] && continue
            printf "[%2s] %s\n" "$score" "$path"
        done

    local status=$?
    set +o pipefail
    return $status
}

# ==========================================================
# Command: brain focus
# ==========================================================
cmd_focus() {

    local file="${1:-}"

    [[ -z "${file:-}" ]] && { _focus_usage; return 1; }

    [[ -f "$file" ]] || {
        log_error "File not found: $file"
        return 1
    }

    session_set_active "$file"
    log_info "[context] Focused on: $file"

    cmd_context "$file"
}
