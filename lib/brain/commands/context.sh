#!/usr/bin/env bash
# ==========================================================
# Brain Context Command
# ==========================================================

source "$MODULES_ROOT/memory/context/resolver.sh"
source "$MODULES_ROOT/memory/context/scorer.sh"
source "$MODULES_ROOT/memory/context/session.sh"

cmd_context() {

    local file="$1"

    # --- Argument validation ---
    [[ -z "$file" ]] && {
        log_error "Usage: brain context <file>"
        return 1
    }

    [[ -f "$file" ]] || {
        log_error "File not found: $file"
        return 1
    }

    log_info "Resolving context for $file"

    # --- Safe pipeline ---
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
    log_info "Focused on: $file"

    cmd_context "$file"
}
