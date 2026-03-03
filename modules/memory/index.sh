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
    local title hash mtime size content

    title="$(extract_title "$file")"
    hash="$(compute_hash "$file")"
    mtime="$(file_mtime "$file")"
    size="$(file_size "$file")"
    content="$(cat "$file")"

    # -------------------------
    # Atomic transaction
    # -------------------------
    {
        begin_tx

        metadata_sql "$file" "$title" "$hash" "$mtime" "$size"
        fts_sql "$file" "$title" "$content"
        tags_sql "$file" "$file"
        links_sql "$file" "$file"

        commit_tx

    } | sqlite3 "$BRAIN_DB" || {
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
            require_file "$file"

            local title hash mtime size content

            title="$(extract_title "$file")"
            hash="$(compute_hash "$file")"
            mtime="$(file_mtime "$file")"
            size="$(file_size "$file")"
            content="$(cat "$file")"

            metadata_sql "$file" "$title" "$hash" "$mtime" "$size"
            fts_sql "$file" "$title" "$content"
            tags_sql "$file" "$file"
            links_sql "$file" "$file"
        done

        # -------------------------
        # Integrated Garbage Collector
        # -------------------------
        gc_sql "$BRAIN_NOTES_DIR"

        commit_tx

    } | sqlite3 "$BRAIN_DB" || {
        echo "[Memory][ERROR] Batch reindex transaction failed" >&2
        return 1
    }

    echo "[Memory] Batch reindex complete (v2.7)"
}
