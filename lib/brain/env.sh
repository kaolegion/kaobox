#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Environment Configuration
# ----------------------------------------------------------
# - Idempotent
# - Portable root detection
# - Safe overrides
# - Readonly guarantees
# - Multi-brain ready
# ==========================================================


# ----------------------------------------------------------
# Prevent double loading
# ----------------------------------------------------------

[[ -n "${BRAIN_ENV_LOADED:-}" ]] && return 0
readonly BRAIN_ENV_LOADED=1


# ----------------------------------------------------------
# Detect KaoBox root (portable install)
# ----------------------------------------------------------

if [[ -z "${KAOBOX_ROOT:-}" ]]; then
    SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    KAOBOX_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
fi

readonly KAOBOX_ROOT


# ----------------------------------------------------------
# Base paths (allow override BEFORE sourcing)
# ----------------------------------------------------------

: "${BRAIN_ROOT:=/data/brain}"

# modules shipped with KaoBox
: "${MODULES_ROOT:=$KAOBOX_ROOT/modules}"

readonly BRAIN_ROOT
readonly MODULES_ROOT


# ----------------------------------------------------------
# Derived paths
# ----------------------------------------------------------

: "${NOTES_DIR:=$BRAIN_ROOT/notes}"
: "${INDEX_DIR:=$BRAIN_ROOT/.index}"
: "${BRAIN_DB:=$INDEX_DIR/brain.db}"
: "${LOG_DIR:=$KAOBOX_ROOT/logs}"

# Memory engine entrypoint
: "${INDEX_SCRIPT:=$MODULES_ROOT/memory/index.sh}"

readonly NOTES_DIR
readonly INDEX_DIR
readonly BRAIN_DB
readonly LOG_DIR
readonly INDEX_SCRIPT


# ----------------------------------------------------------
# Ensure critical directories exist
# ----------------------------------------------------------

mkdir -p \
    "$BRAIN_ROOT" \
    "$NOTES_DIR" \
    "$INDEX_DIR" \
    "$LOG_DIR"


# ----------------------------------------------------------
# Runtime dependency checks
# ----------------------------------------------------------

if ! command -v sqlite3 >/dev/null 2>&1; then
    echo "KaoBox Brain error: sqlite3 is required but not installed."
    exit 1
fi


# ----------------------------------------------------------
# Export environment
# ----------------------------------------------------------

export \
    KAOBOX_ROOT \
    BRAIN_ROOT \
    MODULES_ROOT \
    NOTES_DIR \
    INDEX_DIR \
    BRAIN_DB \
    LOG_DIR \
    INDEX_SCRIPT
