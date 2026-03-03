#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Index Orchestrator (v2.5)
# ----------------------------------------------------------
# - Public API
# - Strict transaction control
# - Explicit note_id propagation
# - Integrated GC
# ==========================================================

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE="$BASE_DIR/engine"

source "$ENGINE/utils.sh"
source "$ENGINE/tx.sh"
source "$ENGINE/metadata.sh"
source "$ENGINE/fts.sh"
source "$ENGINE/tags.sh"
source "$ENGINE/links.sh"
source "$BASE_DIR/gc.sh"

[[ -n "${BRAIN_DB:-}" ]] || {
    echo "[Memory] BRAIN_DB not defined"
    exit 1
}

[[ -f "$BRAIN_DB" ]] || {
    echo "[Memory] Database not found: $BRAIN_DB"
    exit 1
}

# ----------------------------------------------------------
# INDEX SINGLE NOTE
# ----------------------------------------------------------

index_note() {
    local file="$1"

    require_absolute "$file"
    require_file "$file"

    local title hash mtime size content

    title="$(extract_title "$file")"
    hash="$(compute_hash "$file")"
    mtime="$(file_mtime "$file")"
    size="$(file_size "$file")"
    content="$(cat "$file")"

    {
        begin_tx

        # 1️⃣ Upsert note
        metadata_sql "$file" "$title" "$hash" "$mtime" "$size"

        # 2️⃣ Use deterministic SQL note_id
        local note_id="(SELECT id FROM notes WHERE path='$(sql_escape "$file")')"

        # 3️⃣ FTS
        fts_sql "$note_id" "$title" "$content"

        # 4️⃣ Tags
        tags_sql "$note_id" "$file"

        # 5️⃣ Links
        links_sql "$note_id" "$file"

        commit_tx

    } | sqlite3 "$BRAIN_DB"

    echo "[Memory] Indexed (v2.6): $file"
}

# ----------------------------------------------------------
# BATCH REINDEX
# ----------------------------------------------------------

reindex_all() {
    local files=("$@")
    [[ ${#files[@]} -eq 0 ]] && return 0

    {
        begin_tx

        for file in "${files[@]}"; do
            require_file "$file"

            local title hash mtime size content note_id

            title="$(extract_title "$file")"
            hash="$(compute_hash "$file")"
            mtime="$(file_mtime "$file")"
            size="$(file_size "$file")"
            content="$(cat "$file")"

            metadata_sql "$file" "$title" "$hash" "$mtime" "$size"
            note_id="(SELECT id FROM notes WHERE path='$(sql_escape "$file")')"

            fts_sql "$note_id" "$title" "$content"
            tags_sql "$note_id" "$file"
            links_sql "$note_id" "$file"
        done

        # ♻️ Garbage collector intégré
        gc_sql

        commit_tx

    } | sqlite3 "$BRAIN_DB"

    echo "[Memory] Batch reindex complete (v2.5)"
}
