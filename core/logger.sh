#!/usr/bin/env bash
# ==========================================
# KAOBOX MODULE: logger
# Description: Central logging system
# Author: KAOBOX
# Version: Golden-V1
# ==========================================

# Prevent multiple sourcing
[[ -n "${KAOBOX_LOGGER_LOADED:-}" ]] && return
readonly KAOBOX_LOGGER_LOADED=1

# --------------------------------------------------
# Dependencies
# --------------------------------------------------

# Requires env.sh
# TODO: enforce sourcing order via sanity later

# --------------------------------------------------
# Internal Helpers
# --------------------------------------------------

_kaobox_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

_kaobox_write_log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(_kaobox_timestamp)"

    local formatted="[$timestamp] [$level] $message"

    # Write to file if possible
    if [[ -n "${KAOBOX_LOG_FILE:-}" ]]; then
        printf "%s\n" "$formatted" >> "$KAOBOX_LOG_FILE" 2>/dev/null
    fi

    # Console output rules
    case "$level" in
        ERROR)
            printf "%s\n" "$formatted" >&2
            ;;
        WARN|INFO)
            printf "%s\n" "$formatted"
            ;;
        DEBUG)
            if [[ "${KAOBOX_DEBUG:-0}" -eq 1 ]]; then
                printf "%s\n" "$formatted"
            fi
            ;;
    esac
}

# --------------------------------------------------
# Public API
# --------------------------------------------------

log_info() {
    _kaobox_write_log "INFO" "$1"
}

log_warn() {
    _kaobox_write_log "WARN" "$1"
}

log_error() {
    _kaobox_write_log "ERROR" "$1"
}

log_debug() {
    _kaobox_write_log "DEBUG" "$1"
}
