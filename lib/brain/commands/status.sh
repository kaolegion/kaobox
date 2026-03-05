#!/usr/bin/env bash
# ==========================================================
# KAOBOX - Status Command
# ----------------------------------------------------------
# Displays Brain system health and environment state
# ==========================================================

cmd_status() {

    log_info "KaoBox Brain Status"

    echo "----------------------------------------"
    echo "KAOBOX_ROOT : $KAOBOX_ROOT"
    echo "BRAIN_ROOT  : $BRAIN_ROOT"
    echo "BRAIN_DB    : $BRAIN_DB"
    echo "LOG_DIR     : $LOG_DIR"
    echo "Log Level   : ${KAOBOX_LOG_LEVEL:-INFO}"
    echo "----------------------------------------"

    if [[ -f "$BRAIN_DB" ]]; then
        log_info "Brain DB detected."
    else
        log_warn "Brain DB not found."
    fi

    echo "System OK"
}
