#!/usr/bin/env bash

# ---------------------------------------------
# KaoBox Brain Environment Configuration
# ---------------------------------------------

# Base paths
readonly BRAIN_ROOT="/data/brain"
readonly MODULES_ROOT="/opt/kaobox/modules"

# Derived paths
readonly NOTES_DIR="$BRAIN_ROOT/notes"
readonly INDEX_DIR="$BRAIN_ROOT/.index"
readonly BRAIN_DB="$INDEX_DIR/brain.db"
readonly INDEX_SCRIPT="$MODULES_ROOT/memory/index.sh"

# Exports sources
export BRAIN_ROOT
export MODULES_ROOT
export NOTES_DIR
export INDEX_DIR
export BRAIN_DB
export INDEX_SCRIPT
