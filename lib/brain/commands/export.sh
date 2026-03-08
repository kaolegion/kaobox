#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox Brain - Export Command
# ----------------------------------------------------------
# Responsibilities:
#   - CLI-facing export orchestration
#   - Keep command layer thin
#   - Delegate export logic to modules/memory/export.sh
#
# Supported:
#   brain export graph
#   brain export graph --format tsv
# ==========================================================

# ----------------------------------------------------------
# Prevent double loading
# ----------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    [[ -n "${BRAIN_CMD_EXPORT_LOADED:-}" ]] && return 0
    readonly BRAIN_CMD_EXPORT_LOADED=1
fi

# ----------------------------------------------------------
# Help
# ----------------------------------------------------------
_export_usage() {
    echo "[ERROR] Usage: brain export graph [--format tsv]"
}

# ----------------------------------------------------------
# Public command
# ----------------------------------------------------------
cmd_export() {

    [[ $# -ge 1 ]] || {
        _export_usage
        return 1
    }

    local target="$1"
    shift || true

    case "$target" in
        graph)
            cmd_export_graph "$@"
            ;;
        *)
            echo "[ERROR] Unknown export target: $target"
            _export_usage
            return 1
            ;;
    esac
}

# ----------------------------------------------------------
# Graph export
# ----------------------------------------------------------
cmd_export_graph() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[ERROR] BRAIN_DB not defined"
        return 1
    }

    [[ -f "$BRAIN_DB" ]] || {
        echo "[ERROR] Brain DB not found: $BRAIN_DB"
        return 1
    }

    declare -f export_graph_edges_tsv >/dev/null 2>&1 || {
        echo "[ERROR] export_graph_edges_tsv not available"
        return 1
    }

    local format="tsv"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --format)
                shift || true
                [[ $# -ge 1 ]] || {
                    echo "[ERROR] Missing value for --format"
                    return 1
                }
                format="$1"
                shift || true
                ;;
            --format=*)
                format="${1#--format=}"
                shift || true
                ;;
            *)
                echo "[ERROR] Unknown argument: $1"
                _export_usage
                return 1
                ;;
        esac
    done

    case "$format" in
        tsv)
            export_graph_edges_tsv
            ;;
        *)
            echo "[ERROR] Unsupported export format: $format"
            return 1
            ;;
    esac
}
