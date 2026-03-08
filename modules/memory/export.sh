#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox - Memory Graph Export Layer
# ----------------------------------------------------------
# - Read-only
# - Deterministic
# - No side effects
# - Module-level export API
#
# Current canonical export:
#   export_graph_edges_tsv
#
# Output format:
#   source_path<TAB>target_path
# ==========================================================

# ----------------------------------------------------------
# Prevent double loading when sourced
# ----------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    [[ -n "${BRAIN_EXPORT_LOADED:-}" ]] && return 0
    readonly BRAIN_EXPORT_LOADED=1
fi

# ----------------------------------------------------------
# Internal validation
# ----------------------------------------------------------
_export_require_db() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Export] BRAIN_DB not defined" >&2
        return 1
    }

    [[ -f "$BRAIN_DB" ]] || {
        echo "[Export] Database not found: $BRAIN_DB" >&2
        return 1
    }
}

# ----------------------------------------------------------
# Internal SQLite wrapper
# ----------------------------------------------------------
_sqlite_export_exec() {
    sqlite3 -batch -noheader -separator $'\t' "$BRAIN_DB"
}

# ----------------------------------------------------------
# Export: canonical graph edges (TSV)
# ----------------------------------------------------------
# Output:
#   source_path<TAB>target_path
#
# Guarantees:
#   - read-only
#   - deterministic ordering
#   - no duplicates beyond schema truth
# ----------------------------------------------------------
export_graph_edges_tsv() {

    _export_require_db || return 1

    _sqlite_export_exec <<'SQL'
SELECT
    src.path,
    tgt.path
FROM links l
JOIN notes src ON src.id = l.source_id
JOIN notes tgt ON tgt.id = l.target_id
ORDER BY src.path ASC, tgt.path ASC;
SQL
}

# ----------------------------------------------------------
# Export: graph edge count
# ----------------------------------------------------------
# Convenience helper for tests / observability
# ----------------------------------------------------------
export_graph_edge_count() {

    _export_require_db || return 1

    sqlite3 -batch -noheader "$BRAIN_DB" <<'SQL'
SELECT COUNT(*)
FROM links;
SQL
}
