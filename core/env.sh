#!/usr/bin/env bash
# ==========================================
# KAOBOX MODULE: env
# Global environment variables
# ==========================================

[[ -n "${KAOBOX_ENV_LOADED:-}" ]] && return 0
readonly KAOBOX_ENV_LOADED=1

# --------------------------------------------------
# Core Paths (prefer env, fallback)
# --------------------------------------------------

: "${KAOBOX_ROOT:=/opt/kaobox}"

readonly KAOBOX_ROOT
readonly KAOBOX_CORE="$KAOBOX_ROOT/core"
readonly KAOBOX_LIB="$KAOBOX_ROOT/lib"
readonly KAOBOX_MODULES="$KAOBOX_ROOT/modules"
readonly KAOBOX_I18N="$KAOBOX_ROOT/lang"
readonly KAOBOX_PROFILES="$KAOBOX_ROOT/profiles"

# --------------------------------------------------
# Logs
# --------------------------------------------------

: "${KAOBOX_LOG_DIR:=/var/log}"
readonly KAOBOX_LOG_DIR
readonly KAOBOX_LOG_FILE="$KAOBOX_LOG_DIR/kaobox.log"

# --------------------------------------------------
# System
# --------------------------------------------------

: "${KAOBOX_VERSION:=Golden-V1}"
readonly KAOBOX_VERSION

: "${KAOBOX_RUNTIME:=linux}"
readonly KAOBOX_RUNTIME

# --------------------------------------------------
# Debug (opt-in)
# --------------------------------------------------

: "${KAOBOX_DEBUG:=0}"
export KAOBOX_DEBUG

# --------------------------------------------------
# Export public API (for subshells / tools)
# --------------------------------------------------

export \
  KAOBOX_ROOT \
  KAOBOX_CORE \
  KAOBOX_LIB \
  KAOBOX_MODULES \
  KAOBOX_I18N \
  KAOBOX_PROFILES \
  KAOBOX_LOG_DIR \
  KAOBOX_LOG_FILE \
  KAOBOX_VERSION \
  KAOBOX_RUNTIME
