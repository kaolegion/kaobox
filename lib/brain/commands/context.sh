#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Context Command Layer
# ----------------------------------------------------------
# Layer: Cognitive (Kernel Extension)
# Depends on: context/{resolver,scorer,session}
# ==========================================================

# ----------------------------------------------------------
# Prevent double load
# ----------------------------------------------------------
[[ -n "${BRAIN_CONTEXT_CMD_LOADED:-}" ]] && return 0
readonly BRAIN_CONTEXT_CMD_LOADED=1

# ----------------------------------------------------------
# Load Context Layer (Kernel level)
# ----------------------------------------------------------
source "$KAOBOX_ROOT/lib/brain/context/resolver.sh"
source "$KAOBOX_ROOT/lib/brain/context/scorer.sh"
source "$KAOBOX_ROOT/lib/brain/context/session.sh"

# ==========================================================
# Command: brain context
# ==========================================================

cmd_context() {

    local file="$1"

    [[ -z "$file" ]] && {
        log_error "Usage: brain context <file>"
        return 1
    }

    [[ -f "$file" ]] || {
        log_error "File not found: $file"
        return 1
    }

    log_info "[context] Resolving for $file"

    set -o pipefail

    resolve_context "$file" \
        | score_context \
        | head -10 \
        | while IFS="|" read -r score path; do
            printf "[%2s] %s\n" "$score" "$path"
        done

    local status=$?
    set +o pipefail

    return $status
}

# ==========================================================
# Command: brain focus
# ==========================================================

cmd_focus() {

    local file="$1"

    [[ -z "$file" ]] && {
        log_error "Usage: brain focus <file>"
        return 1
    }

    [[ -f "$file" ]] || {
        log_error "File not found: $file"
        return 1
    }

    session_set_active "$file"
    log_info "[context] Focused on: $file"

    cmd_context "$file"
}
