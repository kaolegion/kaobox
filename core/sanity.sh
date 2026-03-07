#!/usr/bin/env bash
# ==========================================
# KAOBOX MODULE: sanity
# Description: System checks & environment validation
# Author: KAOBOX
# Version: Golden-V1
# ==========================================

# Prevent multiple sourcing
[[ -n "${KAOBOX_SANITY_LOADED:-}" ]] && return
readonly KAOBOX_SANITY_LOADED=1

# --------------------------------------------------
# Dependencies
# --------------------------------------------------

# Requires:
# - env.sh
# - logger.sh
# TODO: enforce strict load order in init.sh

# --------------------------------------------------
# Log Directory
# --------------------------------------------------

ensure_log_directory() {
    if [[ ! -d "$KAOBOX_LOG_DIR" ]]; then
        mkdir -p "$KAOBOX_LOG_DIR" 2>/dev/null || {
            log_error "Unable to create log directory: $KAOBOX_LOG_DIR"
            return 1
        }
        log_info "Created log directory: $KAOBOX_LOG_DIR"
    fi
}

# --------------------------------------------------
# WSL Detection
# --------------------------------------------------

check_wsl() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        log_debug "WSL environment detected"
    else
        log_warn "Not running under WSL (unexpected runtime)"
        # TODO: allow multi-runtime support later
    fi
}

# --------------------------------------------------
# Required Tools
# --------------------------------------------------

check_required_tools() {

    # Core minimal tools
    local required=(
        bash
        grep
        date
    )

    # TODO: extend with:
    # bat eza fd fzf ripgrep jq yazi

    for tool in "${required[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_error "Missing required tool: $tool"
            return 1
        else
            log_debug "Tool OK: $tool"
        fi
    done

    log_info "All required tools available"
}

# --------------------------------------------------
# Permissions
# --------------------------------------------------

check_permissions() {
    if [[ ! -w "$KAOBOX_LOG_DIR" ]]; then
        log_warn "Log directory not writable: $KAOBOX_LOG_DIR"
        # TODO: handle non-root user case cleanly
    fi
}
