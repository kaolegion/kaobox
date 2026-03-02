#!/usr/bin/env bash
# ==========================================
# KAOBOX MODULE: env
# Description: Global environment variables
# Author: KAOBOX
# Version: Golden-V1
# ==========================================

# Prevent multiple sourcing
[[ -n "${KAOBOX_ENV_LOADED:-}" ]] && return
readonly KAOBOX_ENV_LOADED=1

# --------------------------------------------------
# Core Paths
# --------------------------------------------------

readonly KAOBOX_ROOT="/opt/kaobox"
readonly KAOBOX_CORE="$KAOBOX_ROOT/core"
readonly KAOBOX_MODULES="$KAOBOX_ROOT/modules"
readonly KAOBOX_I18N="$KAOBOX_ROOT/i18n"
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
readonly KAOBOX_RUNTIME="wsl"

# --------------------------------------------------
# Debug
# --------------------------------------------------

: "${KAOBOX_DEBUG:=0}"
export KAOBOX_DEBUG
