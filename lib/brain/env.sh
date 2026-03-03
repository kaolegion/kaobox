#!/usr/bin/env bash

# ---------------------------------------------
# KaoBox Brain Environment Configuration
# ---------------------------------------------

# Base paths
readonly BRAIN_ROOT="/data/brain"
readonly MODULES_ROOT="/opt/kaobox/modules"

# Derived paths
readonly BRAIN_DB="$BRAIN_ROOT/.index/brain.db"
readonly NOTES_DIR="$BRAIN_ROOT/notes"
readonly INDEX_SCRIPT="$MODULES_ROOT/memory/index.sh"

# ---------------------------------------------
# Safety checks
# ---------------------------------------------

_check_absolute() {
    [[ "$1" == /* ]] || {
        echo "[ENV ERROR] Path must be absolute: $1"
        return 1
    }
}

_check_absolute "$BRAIN_ROOT"
_check_absolute "$MODULES_ROOT"
_check_absolute "$NOTES_DIR"
_check_absolute "$BRAIN_DB"

# ---------------------------------------------
# Ensure required directories exist
# ---------------------------------------------

mkdir -p "$BRAIN_ROOT/.index"
mkdir -p "$NOTES_DIR"

# ---------------------------------------------
# Ensure DB exists
# ---------------------------------------------

if [[ ! -f "$BRAIN_DB" ]]; then
    echo "[Brain] Initializing database..."
    sqlite3 "$BRAIN_DB" < "$MODULES_ROOT/memory/schema.sql"
fi
