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

[[ -f "$MEMORY_QUERY" ]] || {
    echo "Fatal: missing memory query module"
    exit 1
}

# ----------------------------------------------------------
# Usage
# ----------------------------------------------------------

usage() {
cat <<EOF
🧠 KaoBox Brain CLI

Usage:
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
  brain context <file>
  brain focus <file>

Cognition:
  brain think <query>

Graph:
  brain graph
  brain backlinks

Debug:
  brain stats
  brain explain

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
            
        stats)
			preflight_check
			load_command "stats.sh"
            cmd_stats "$@"
            ;;

		graph)
		    preflight_check
		    load_command "graph.sh"
		    cmd_graph "$@"
		    ;;

		explain)
		    preflight_check
		    load_command "explain.sh"
		    cmd_explain "$@"
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

# TODO: Ajout pour debug dans dispatcher command - brain
# ----------------------------------------------------------
# Mode debug - < Brain
# ----------------------------------------------------------

[[ "$KAOBOX_DEBUG" == 1 ]] && echo "[debug] command=$1"

}
