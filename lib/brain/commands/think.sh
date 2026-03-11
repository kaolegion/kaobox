#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Think Command
# ==========================================================

set -euo pipefail

[[ -n "${BRAIN_THINK_CMD_LOADED:-}" ]] && return 0
readonly BRAIN_THINK_CMD_LOADED=1

safe_source "$KAOBOX_ROOT/lib/brain/think/engine.sh"

_think_usage() {
    log_error "Usage: brain think [--trace] <query>"
}

cmd_think() {
    local trace=0
    local -a args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --trace)
                trace=1
                shift
                ;;
            -h|--help|help)
                _think_usage
                return 0
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done

    local query="${args[*]:-}"

    [[ -z "${query:-}" ]] && {
        _think_usage
        return 1
    }

    log_info "[think] Query: $query"

    if (( trace == 1 )); then
        think_engine_trace "$query"
        return $?
    fi

    think_engine_run "$query"
}
