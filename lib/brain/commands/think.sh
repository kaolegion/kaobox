#!/usr/bin/env bash

[[ -n "${BRAIN_THINK_CMD_LOADED:-}" ]] && return 0
readonly BRAIN_THINK_CMD_LOADED=1

safe_source "$KAOBOX_ROOT/lib/brain/think/engine.sh"

cmd_think() {

    local query="$*"

    [[ -z "$query" ]] && {
        log_error "Usage: brain think <query>"
        return 1
    }

    log_info "[think] Query: $query"

    think_engine_run "$query"
}
