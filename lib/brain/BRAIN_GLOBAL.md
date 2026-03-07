#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox Brain - CLI Dispatcher (Kernel v3.0)
# Deterministic • Modular • Safe
# ==========================================================

# ----------------------------------------------------------
# Prevent double loading
# ----------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    [[ -n "${BRAIN_DISPATCHER_LOADED:-}" ]] && return 0
    readonly BRAIN_DISPATCHER_LOADED=1
fi

# ----------------------------------------------------------
# Detect Root
# ----------------------------------------------------------

if [[ -z "${KAOBOX_ROOT:-}" ]]; then
    KAOBOX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
export KAOBOX_ROOT

# ----------------------------------------------------------
# Safe source helper
# ----------------------------------------------------------

safe_source() {
    local file="$1"
    [[ -f "$file" ]] || {
        echo "Fatal: missing file $file"
        exit 1
    }
    # shellcheck source=/dev/null
    source "$file"
}

# ----------------------------------------------------------
# Load Core (ORDER MATTERS)
# ----------------------------------------------------------

safe_source "$KAOBOX_ROOT/lib/brain/env.sh"
safe_source "$KAOBOX_ROOT/core/logger.sh"
safe_source "$KAOBOX_ROOT/lib/brain/preflight.sh"
safe_source "$KAOBOX_ROOT/lib/brain/sanitize.sh"
safe_source "$KAOBOX_ROOT/lib/brain/lock.sh"
safe_source "$KAOBOX_ROOT/lib/brain/renderer.sh"

# ----------------------------------------------------------
# Paths
# ----------------------------------------------------------

readonly COMMANDS_DIR="$KAOBOX_ROOT/lib/brain/commands"
readonly MEMORY_QUERY="$MODULES_ROOT/memory/query.sh"
readonly MEMORY_INDEX="$MODULES_ROOT/memory/index.sh"

# ----------------------------------------------------------
# Usage
# ----------------------------------------------------------

usage() {
cat <<EOF
🧠 KaoBox Brain CLI

Usage:
  brain status
  brain doctor
  brain new "Title"
  brain search <query>
  brain open <file>
  brain ls
  brain reindex
  brain fuzzy
  brain context <file>
  brain focus <file>
  brain think <query>
EOF
}

# ----------------------------------------------------------
# Command Loader
# ----------------------------------------------------------

load_command() {
    local file="$1"
    safe_source "$COMMANDS_DIR/$file"
}

# ----------------------------------------------------------
# Dispatcher
# ----------------------------------------------------------

brain_dispatch() {

    local cmd="${1:-help}"
    [[ $# -gt 0 ]] && shift

    case "$cmd" in

        # ---- System ----
        status)
            load_command "status.sh"
            cmd_status "$@"
            ;;

        doctor)
            load_command "doctor.sh"
            cmd_doctor "$@"
            ;;

        # ---- Memory ----
        new)
            preflight_check
            load_command "new.sh"
            cmd_new "$@"
            ;;

        search)
            preflight_check
            safe_source "$MEMORY_QUERY"
            load_command "search.sh"
            cmd_search "$@"
            ;;

        open)
            preflight_check
            load_command "open.sh"
            cmd_open "$@"
            ;;

        ls)
            preflight_check
            load_command "ls.sh"
            cmd_ls "$@"
            ;;

        reindex)
            preflight_check
            safe_source "$MEMORY_INDEX"
            load_command "reindex.sh"
            cmd_reindex "$@"
            ;;

        fuzzy)
            preflight_check
            load_command "fuzzy.sh"
            cmd_fuzzy "$@"
            ;;

        # ---- Context Layer ----
        context)
            preflight_check
            load_command "context.sh"
            cmd_context "$@"
            ;;

        focus)
            preflight_check
            load_command "context.sh"
            cmd_focus "$@"
            ;;

        # ---- Cognitive Layer ----
        think)
            preflight_check
            load_command "think.sh"
            cmd_think "$@"
            ;;

        help|--help|-h)
            usage
            ;;

        *)
            log_error "Unknown command: $cmd"
            echo
            usage
            exit 1
            ;;
    esac
}
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
#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox Brain - Lock System
# ----------------------------------------------------------
# - Deterministic
# - Idempotent
# - Dynamic FD allocation
# - Safe release
# ==========================================================

[[ -n "${BRAIN_LOCK_LOADED:-}" ]] && return 0
readonly BRAIN_LOCK_LOADED=1

: "${LOCK_DIR:=$INDEX_DIR/.lock}"
: "${LOCK_FILE:=$LOCK_DIR/brain.lock}"

readonly LOCK_DIR
readonly LOCK_FILE

# Dynamic FD (assigned at runtime)
BRAIN_LOCK_FD=""

acquire_lock() {

    # Prevent double acquisition in same process
    if [[ -n "${BRAIN_LOCK_FD:-}" ]]; then
        echo "[Brain] Lock already acquired in this process."
        return 1
    fi

    mkdir -p "$LOCK_DIR"

    exec {BRAIN_LOCK_FD}>"$LOCK_FILE"

    if ! flock -n "$BRAIN_LOCK_FD"; then
        exec {BRAIN_LOCK_FD}>&-
        BRAIN_LOCK_FD=""
        echo "[Brain] Another process is running. Aborting."
        return 1
    fi
}

release_lock() {

    if [[ -z "${BRAIN_LOCK_FD:-}" ]]; then
        return 0
    fi

    flock -u "$BRAIN_LOCK_FD" 2>/dev/null || true
    exec {BRAIN_LOCK_FD}>&- 2>/dev/null || true

    BRAIN_LOCK_FD=""
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Preflight Checks
# ----------------------------------------------------------
# - Idempotent
# - Non-destructive
# - Validates DB integrity
# ==========================================================

[[ -n "${BRAIN_PREFLIGHT_LOADED:-}" ]] && return 0
readonly BRAIN_PREFLIGHT_LOADED=1

preflight_check() {

    # 1️⃣ Environment sanity
    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[FATAL] BRAIN_DB not defined"
        return 1
    }

    [[ -n "${INDEX_DIR:-}" ]] || {
        echo "[FATAL] INDEX_DIR not defined"
        return 1
    }

    # 2️⃣ Directory existence
    [[ -d "$INDEX_DIR" ]] || {
        echo "[FATAL] Index directory not found: $INDEX_DIR"
        return 1
    }

    # 3️⃣ Database existence
    [[ -f "$BRAIN_DB" ]] || {
        echo "[FATAL] Brain database not found at $BRAIN_DB"
        return 1
    }

    # 4️⃣ SQLite integrity check
    if ! sqlite3 "$BRAIN_DB" "PRAGMA integrity_check;" | grep -q "ok"; then
        echo "[FATAL] Brain database integrity check failed"
        return 1
    fi

    return 0
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Output Renderer
# ----------------------------------------------------------
# - Idempotent
# - CLI Table mode
# - JSON mode
# - Unified formatting layer
# ==========================================================

[[ -n "${BRAIN_RENDERER_LOADED:-}" ]] && return 0
readonly BRAIN_RENDERER_LOADED=1

RENDER_MODE="${RENDER_MODE:-table}"   # table | json | raw

# ----------------------------------------------------------
# Internal: escape JSON
# ----------------------------------------------------------

_json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# ----------------------------------------------------------
# Render Table
# ----------------------------------------------------------

_render_table() {

    local rows=("$@")

    [[ ${#rows[@]} -eq 0 ]] && {
        echo "No results."
        return 0
    }

    printf "%-6s %-30s %s\n" "ID" "TITLE" "PATH"
    printf "%-6s %-30s %s\n" "----" "------------------------------" "---------------------------"

    for row in "${rows[@]}"; do
        IFS=$'\t' read -r id path title score <<< "$row"
        printf "%-6s %-30s %s\n" "$id" "${title:0:28}" "$path"
    done
}

# ----------------------------------------------------------
# Render JSON
# ----------------------------------------------------------

_render_json() {

    local rows=("$@")

    printf "[\n"
    local first=1

    for row in "${rows[@]}"; do
        IFS=$'\t' read -r id path title score <<< "$row"

        [[ $first -eq 0 ]] && printf ",\n"
        first=0

        printf "  {\n"
        printf "    \"id\": \"%s\",\n" "$(_json_escape "$id")"
        printf "    \"path\": \"%s\",\n" "$(_json_escape "$path")"
        printf "    \"title\": \"%s\",\n" "$(_json_escape "$title")"
        printf "    \"score\": \"%s\"\n" "$(_json_escape "${score:-}")"
        printf "  }"
    done

    printf "\n]\n"
}

# ----------------------------------------------------------
# Public API
# ----------------------------------------------------------

render_results() {

    local mode="${1:-$RENDER_MODE}"
    shift || true

    local rows=("$@")

    case "$mode" in
        table)
            _render_table "${rows[@]}"
            ;;
        json)
            _render_json "${rows[@]}"
            ;;
        raw)
            printf "%s\n" "${rows[@]}"
            ;;
        *)
            echo "[Renderer] Unknown mode: $mode"
            return 1
            ;;
    esac
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Input Sanitization
# ----------------------------------------------------------
# - Idempotent
# - Safe for SQL
# - Preserves FTS operators
# ==========================================================

[[ -n "${BRAIN_SANITIZE_LOADED:-}" ]] && return 0
readonly BRAIN_SANITIZE_LOADED=1

sanitize_sql() {
    # Escape single quotes for SQLite
    local input="$1"
    printf "%s" "$input" | sed "s/'/''/g"
}

sanitize_fts() {
    local input="$1"

    # Remove only dangerous SQL control characters
    # Preserve: letters, numbers, space, _, -, *, :, ", parentheses
    printf "%s" "$input" \
        | tr -cd '[:alnum:] _-*:"()'
}
