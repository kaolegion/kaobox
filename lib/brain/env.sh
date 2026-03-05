#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Environment Configuration
# ----------------------------------------------------------
# - Idempotent
# - Portable (auto-detect root)
# - Safe overrides
# - Readonly guarantees
# - Future multi-brain ready
# ==========================================================

# Prevent double loading
[[ -n "${BRAIN_ENV_LOADED:-}" ]] && return 0
readonly BRAIN_ENV_LOADED=1

# ----------------------------------------------------------
# Detect KaoBox root (portable install)
# ----------------------------------------------------------

if [[ -z "${KAOBOX_ROOT:-}" ]]; then
    KAOBOX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
fi

readonly KAOBOX_ROOT
export KAOBOX_ROOT

# ----------------------------------------------------------
# Base paths (allow override BEFORE sourcing)
# ----------------------------------------------------------

: "${BRAIN_ROOT:=/data/brain}"

# Modules live relative to installation
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

# Memory Engine entrypoint
: "${INDEX_SCRIPT:=$MODULES_ROOT/memory/index.sh}"

readonly NOTES_DIR
readonly INDEX_DIR
readonly BRAIN_DB
readonly LOG_DIR
readonly INDEX_SCRIPT

# ----------------------------------------------------------
# Ensure critical directories exist
# ----------------------------------------------------------

mkdir -p "$BRAIN_ROOT" "$INDEX_DIR" "$LOG_DIR" 2>/dev/null

# ----------------------------------------------------------
# Export environment
# ----------------------------------------------------------

export BRAIN_ROOT
export MODULES_ROOT
export NOTES_DIR
export INDEX_DIR
export BRAIN_DB
export LOG_DIR
export INDEX_SCRIPT
