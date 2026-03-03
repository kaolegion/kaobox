#!/usr/bin/env bash

readonly LOG_DIR="/var/log/kaobox"
readonly LOG_FILE="$LOG_DIR/brain.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR" 2>/dev/null || true

log() {
    local level="${1:-INFO}"
    shift || true
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    {
        flock 200
        printf "%s | %-5s | %s\n" "$timestamp" "$level" "$message"
    } 200>>"$LOG_FILE"
}
