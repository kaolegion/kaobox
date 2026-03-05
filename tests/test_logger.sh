#!/usr/bin/env bash
set -e

source core/logger.sh

echo "Testing logger..."

log_info "Info OK"
log_warn "Warn OK"
log_error "Error OK"
log_debug "Debug OK"

echo "Logger test complete."
