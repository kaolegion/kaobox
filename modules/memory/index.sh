#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Index Orchestrator (v2.7 Stable)
# ----------------------------------------------------------
# Responsibilities:
#   - Public API
#   - Strict transaction control
#   - Atomic single index
#   - Transactional batch reindex
#   - Integrated Garbage Collector
#
# Design:
#   - Engine emits SQL only
#   - Orchestrator pipes to sqlite3
#   - No direct DB logic outside pipeline
# ==========================================================

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE="$BASE_DIR/engine"

source "$ENGINE/utils.sh"
source "$ENGINE/tx.sh"
source "$ENGINE/metadata.sh"
source "$ENGINE/fts.sh"
source "$ENGINE/tags.sh"
source "$ENGINE/links.sh"
source "$BASE_DIR/gc.sh"

# ----------------------------------------------------------
# ENVIRONMENT VALIDATION
# ----------------------------------------------------------

[[ -n "${BRAIN_DB:-}" ]] || {
    echo "[Memory][ERROR] BRAIN_DB not defined" >&2
    exit 1
}

[[ -f "$BRAIN_DB" ]] || {
    echo "[Memory][ERROR] Database not found: $BRAIN_DB" >&2
    exit 1
}

# Default notes directory (can be overridden)
BRAIN_NOTES_DIR="${BRAIN_NOTES_DIR:-/data/brain/notes}"

# ==========================================================
# INDEX SINGLE NOTE
# ==========================================================

index_note() {
    local file="$1"

    # -------------------------
    # Preconditions
    # -------------------------
    require_absolute "$file"
    require_file "$file"

    # -------------------------
    # Extract metadata
    # -------------------------

    analyze_file "$file"

    # -------------------------
    # Atomic transaction
    # -------------------------
    {
        begin_tx

        metadata_sql "$file" "$FILE_TITLE" "$FILE_HASH" "$FILE_MTIME" "$FILE_SIZE"
        fts_sql "$file" "$FILE_TITLE" "$FILE_CONTENT"
        tags_sql "$file" "$file"
        links_sql "$file" "$file"

        commit_tx

    } | sqlite3 -batch "$BRAIN_DB" -cmd ".timeout 5000" || {
        echo "[Memory][ERROR] Index transaction failed: $file" >&2
        return 1
    }

    echo "[Memory] Indexed (v2.7): $file"
}

# ==========================================================
# BATCH REINDEX
# ==========================================================

reindex_all() {
    local files=("$@")
    [[ ${#files[@]} -eq 0 ]] && return 0

    {
        begin_tx

        for file in "${files[@]}"; do
            require_absolute "$file"
            require_file "$file"

            analyze_file "$file"

            metadata_sql "$file" "$FILE_TITLE" "$FILE_HASH" "$FILE_MTIME" "$FILE_SIZE"
            fts_sql "$file" "$FILE_TITLE" "$FILE_CONTENT"
            tags_sql "$file" "$file"
            links_sql "$file" "$file"
        done
		# -------------------------
        # Integrated Garbage Collector
        # -------------------------
        gc_sql "$BRAIN_NOTES_DIR"

		commit_tx
		} | sqlite3 -batch "$BRAIN_DB" -cmd ".timeout 5000" || {
		    echo "[Memory][ERROR] Batch reindex failed" >&2
		    return 1
		}
		
		# ---------------------------------------------------------
		# WAL Checkpoint (intelligent - batch only)
		# ---------------------------------------------------------
		
		sqlite3 -batch "$BRAIN_DB" -cmd ".timeout 5000" \
		    "PRAGMA wal_checkpoint(TRUNCATE);" >/dev/null 2>&1
		
		# ---------------------------------------------------------
		# SQLite Optimize (post-batch maintenance)
		# ---------------------------------------------------------
		
		sqlite3 -batch "$BRAIN_DB" -cmd ".timeout 5000" \
		    "PRAGMA optimize;" >/dev/null 2>&1
		
		log INFO "Batch reindex completed (${#files[@]} files)"
}
