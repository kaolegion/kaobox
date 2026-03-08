#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox - Memory Index Orchestrator (Module Pure)
# ==========================================================

[[ -n "${BRAIN_INDEX_LOADED:-}" ]] && return 0
readonly BRAIN_INDEX_LOADED=1

# ----------------------------------------------------------
# Environment validation (module must not exit shell)
# ----------------------------------------------------------
[[ -n "${BRAIN_DB:-}" ]] || {
    echo "[Memory][ERROR] BRAIN_DB not defined" >&2
    return 1
}

[[ -f "$BRAIN_DB" ]] || {
    echo "[Memory][ERROR] Database not found: $BRAIN_DB" >&2
    return 1
}

# ----------------------------------------------------------
# Engine bootstrap
# ----------------------------------------------------------
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE="$BASE_DIR/engine"

# shellcheck source=/dev/null
source "$ENGINE/utils.sh"
# shellcheck source=/dev/null
source "$ENGINE/tx.sh"
# shellcheck source=/dev/null
source "$ENGINE/metadata.sh"
# shellcheck source=/dev/null
source "$ENGINE/fts.sh"
# shellcheck source=/dev/null
source "$ENGINE/tags.sh"
# shellcheck source=/dev/null
source "$ENGINE/links.sh"
# shellcheck source=/dev/null
source "$BASE_DIR/gc.sh"

# ----------------------------------------------------------
# Notes directory (respects env)
# ----------------------------------------------------------
: "${BRAIN_NOTES_DIR:=$NOTES_DIR}"
readonly BRAIN_NOTES_DIR

# ----------------------------------------------------------
# SQLite wrapper
# ----------------------------------------------------------
_sqlite_index_exec() {
    sqlite3 -batch "$BRAIN_DB" -cmd ".timeout 5000"
}

# ==========================================================
# INDEX SINGLE NOTE
# ==========================================================
index_note() {

    local file="${1:-}"
    [[ -n "$file" ]] || {
        echo "[Memory][ERROR] Missing file path for index_note" >&2
        return 1
    }

    require_absolute "$file"
    require_file "$file"
    analyze_file "$file"

    {
        begin_tx

        metadata_sql "$file" "$FILE_TITLE" "$FILE_HASH" "$FILE_MTIME" "$FILE_SIZE"
        fts_sql "$file" "$FILE_TITLE" "$FILE_CONTENT"
        tags_sql "$file" "$file"
        links_sql "$file" "$file"

        commit_tx
    } | _sqlite_index_exec || {
        echo "[Memory][ERROR] Index transaction failed: $file" >&2
        return 1
    }

    log INFO "Indexed: $file"
}

# ==========================================================
# BATCH REINDEX
# ----------------------------------------------------------
# Two-pass model:
#   Pass 1 -> metadata / fts / tags
#   Pass 2 -> links
#
# Rationale:
#   Links may target notes that appear later in lexical order.
#   All notes must exist in the DB before graph resolution.
# ==========================================================
reindex_all() {

    local files=("$@")
    [[ ${#files[@]} -eq 0 ]] && return 0

    local file
    {
        begin_tx

        # --------------------------------------------------
        # PASS 1: materialize notes first
        # --------------------------------------------------
        for file in "${files[@]}"; do
            require_absolute "$file"
            require_file "$file"
            analyze_file "$file"

            metadata_sql "$file" "$FILE_TITLE" "$FILE_HASH" "$FILE_MTIME" "$FILE_SIZE"
            fts_sql "$file" "$FILE_TITLE" "$FILE_CONTENT"
            tags_sql "$file" "$file"
        done

        # --------------------------------------------------
        # PASS 2: resolve graph links after all notes exist
        # --------------------------------------------------
        for file in "${files[@]}"; do
            require_absolute "$file"
            require_file "$file"
            links_sql "$file" "$file"
        done

        gc_sql "$BRAIN_NOTES_DIR"

        commit_tx
    } | _sqlite_index_exec || {
        echo "[Memory][ERROR] Batch reindex failed" >&2
        return 1
    }

    # WAL maintenance (non critical)
    sqlite3 -batch "$BRAIN_DB" "PRAGMA wal_checkpoint(TRUNCATE);" >/dev/null 2>&1 || true
    sqlite3 -batch "$BRAIN_DB" "PRAGMA optimize;" >/dev/null 2>&1 || true

    log INFO "Batch reindex completed (${#files[@]} files)"
}
