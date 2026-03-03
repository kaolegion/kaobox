#!/usr/bin/env bash

readonly LOCK_DIR="/data/brain/.lock"
readonly LOCK_FILE="$LOCK_DIR/brain.lock"

mkdir -p "$LOCK_DIR" 2>/dev/null || true

acquire_lock() {

    exec 200>"$LOCK_FILE" || {
        echo "[Brain] Unable to open lock file."
        return 1
    }

    flock -n 200 || {
        echo "[Brain] Another process is running. Aborting."
        return 1
    }
}

release_lock() {
    flock -u 200 2>/dev/null || true
    exec 200>&- 2>/dev/null || true
}
