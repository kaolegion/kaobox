#!/usr/bin/env bash
# ==========================================================
# KAOBOX CORE LOGGER
# ----------------------------------------------------------
# Centralized logging system for all KaoBox modules.
# Supports log levels, file output, debug control,
# and future structured logging.
#
# Version: Kernel-V2
# ==========================================================

# Prevent multiple sourcing
[[ -n "${KAOBOX_LOGGER_LOADED:-}" ]] && return
readonly KAOBOX_LOGGER_LOADED=1

# ----------------------------------------------------------
# Configuration
# ----------------------------------------------------------

# Log levels priority
# DEBUG=0 INFO=1 WARN=2 ERROR=3
KAOBOX_LOG_LEVEL="${KAOBOX_LOG_LEVEL:-INFO}"

# Optional log file (ex: /opt/kaobox/logs/kaobox.log)
# export KAOBOX_LOG_FILE="/opt/kaobox/logs/kaobox.log"

# ----------------------------------------------------------
# Internal Helpers
# ----------------------------------------------------------

_kaobox_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

_kaobox_level_to_int() {
    case "$1" in
        DEBUG) echo 0 ;;
        INFO)  echo 1 ;;
        WARN)  echo 2 ;;
        ERROR) echo 3 ;;
        *)     echo 1 ;;
    esac
}

_kaobox_should_log() {
    local incoming="$1"
    local current

    current="$(_kaobox_level_to_int "$KAOBOX_LOG_LEVEL")"
    incoming="$(_kaobox_level_to_int "$incoming")"

    [[ "$incoming" -ge "$current" ]]
}

_kaobox_write_log() {
    local level="$1"
    shift
    local message="$*"

    _kaobox_should_log "$level" || return 0

    local timestamp
    timestamp="$(_kaobox_timestamp)"

    local formatted="[$timestamp] [$level] $message"

    # File output
    if [[ -n "${KAOBOX_LOG_FILE:-}" ]]; then
        printf "%s\n" "$formatted" >> "$KAOBOX_LOG_FILE" 2>/dev/null
    fi

    # Console routing
    if [[ "$level" == "ERROR" ]]; then
        printf "%s\n" "$formatted" >&2
    else
        printf "%s\n" "$formatted"
    fi
}

# ----------------------------------------------------------
# Public API
# ----------------------------------------------------------

log() {
    local level="$1"
    shift
    _kaobox_write_log "$level" "$@"
}

log_debug() { log DEBUG "$@"; }
log_info()  { log INFO  "$@"; }
log_warn()  { log WARN  "$@"; }
log_error() { log ERROR "$@"; }
