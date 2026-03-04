#!/usr/bin/env bash

readonly LOG_DIR="$BRAIN_ROOT/logs"
readonly LOG_FILE="$LOG_DIR/brain.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# FD 201 reserved for logger
log() {
    local level="${1:-INFO}"
    shift || true
    local message="$*"
    local timestamp

    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    {
        flock -x 201
        printf "%s | %-5s | %s\n" "$timestamp" "$level" "$message"
    } 201>>"$LOG_FILE"
}
