#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox Brain - CLI Dispatcher (Kernel v3.1)
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
readonly MEMORY_EXPORT="$MODULES_ROOT/memory/export.sh"

# ----------------------------------------------------------
# Required module checks
# ----------------------------------------------------------
[[ -f "$MEMORY_QUERY" ]] || {
    echo "Fatal: missing memory query module"
    exit 1
}

[[ -f "$MEMORY_INDEX" ]] || {
    echo "Fatal: missing memory index module"
    exit 1
}

[[ -f "$MEMORY_EXPORT" ]] || {
    echo "Fatal: missing memory export module"
    exit 1
}

# ----------------------------------------------------------
# Usage
# ----------------------------------------------------------
usage() {
cat <<'EOF'
🧠 KaoBox Brain CLI

System:
  brain status
  brain doctor

Memory:
  brain new "Title"
  brain open <file>
  brain ls
  brain search <query>
  brain fuzzy
  brain reindex

Context:
  brain context [--trace] <file>
  brain focus <file>
  brain session

Cognition:
  brain think <query>

Graph:
  brain graph <note>
  brain backlinks <note>
  brain neighbors <note>
  brain related <note>
  brain path <from_note> <to_note>

Export:
  brain export graph
  brain export graph --format tsv

Observability:
  brain health
  brain stats
  brain explain [--trace] <query>

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
    shift || true

    # ------------------------------------------------------
    # Debug mode (deterministic, stderr)
    # ------------------------------------------------------
    if [[ "${KAOBOX_DEBUG:-0}" == "1" ]]; then
        echo "[debug] cmd=$cmd args=$*" >&2
    fi

    case "$cmd" in

        # --------------------------------------------------
        # System
        # --------------------------------------------------
        status)
            load_command "status.sh"
            cmd_status "$@"
            ;;

        doctor)
            load_command "doctor.sh"
            cmd_doctor "$@"
            ;;

        # --------------------------------------------------
        # Observability
        # --------------------------------------------------
        health)
            preflight_check
            load_command "health.sh"
            cmd_health "$@"
            ;;

        session)
            preflight_check
            load_command "session.sh"
            cmd_session "$@"
            ;;

        stats)
            preflight_check
            load_command "stats.sh"
            cmd_stats "$@"
            ;;

        explain)
            preflight_check
            load_command "explain.sh"
            cmd_explain "$@"
            ;;

        # --------------------------------------------------
        # Memory
        # --------------------------------------------------
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

        # --------------------------------------------------
        # Context
        # --------------------------------------------------
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

        # --------------------------------------------------
        # Cognition
        # --------------------------------------------------
        think)
            preflight_check
            load_command "think.sh"
            cmd_think "$@"
            ;;

        # --------------------------------------------------
        # Graph
        # --------------------------------------------------
        graph)
            preflight_check
            safe_source "$MEMORY_QUERY"
            load_command "graph.sh"
            cmd_graph "$@"
            ;;

        backlinks)
            preflight_check
            safe_source "$MEMORY_QUERY"
            load_command "backlinks.sh"
            cmd_backlinks "$@"
            ;;

        neighbors)
            preflight_check
            safe_source "$MEMORY_QUERY"
            load_command "neighbors.sh"
            cmd_neighbors "$@"
            ;;

        related)
            preflight_check
            safe_source "$MEMORY_QUERY"
            load_command "related.sh"
            cmd_related "$@"
            ;;

        path)
            preflight_check
            safe_source "$MEMORY_QUERY"
            load_command "path.sh"
            cmd_path "$@"
            ;;

        # --------------------------------------------------
        # Export
        # --------------------------------------------------
        export)
            preflight_check
            safe_source "$MEMORY_EXPORT"
            load_command "export.sh"
            cmd_export "$@"
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
