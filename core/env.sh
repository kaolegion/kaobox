#!/usr/bin/env bash
# ==========================================
# KAOBOX MODULE: env
# Global environment variables
# ==========================================

[[ -n "${KAOBOX_ENV_LOADED:-}" ]] && return
readonly KAOBOX_ENV_LOADED=1

# --------------------------------------------------
# Core Paths
# --------------------------------------------------

readonly KAOBOX_ROOT="/opt/kaobox"
readonly KAOBOX_CORE="$KAOBOX_ROOT/core"
readonly KAOBOX_LIB="$KAOBOX_ROOT/lib"
readonly KAOBOX_MODULES="$KAOBOX_ROOT/modules"
readonly KAOBOX_I18N="$KAOBOX_ROOT/lang"
readonly KAOBOX_PROFILES="$KAOBOX_ROOT/profiles"

# --------------------------------------------------
# Logs
# --------------------------------------------------

readonly KAOBOX_LOG_DIR="/var/log"
readonly KAOBOX_LOG_FILE="$KAOBOX_LOG_DIR/kaobox.log"

# --------------------------------------------------
# System
# --------------------------------------------------

readonly KAOBOX_VERSION="Golden-V1"
readonly KAOBOX_RUNTIME="${KAOBOX_RUNTIME:-linux}"

# --------------------------------------------------
# Debug
# --------------------------------------------------

: "${KAOBOX_DEBUG:=0}"
export KAOBOX_DEBUG
