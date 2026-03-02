cmd_reindex() {

    log "Reindex started"

    echo "[Brain] Reindexing all notes..."

    find "$NOTES_DIR" -type f -name "*.md" | while read -r file; do
        "$INDEX_SCRIPT" index "$file"
    done

    echo "[Brain] Reindex complete."

    log "Reindex completed"
}
