cmd_doctor() {

    echo "[Brain] Running diagnostics..."

    # ----------------------------------
    # Check database file
    # ----------------------------------

    if [[ ! -f "$BRAIN_DB" ]]; then
        echo "❌ Database missing: $BRAIN_DB"
        return 1
    fi

    if [[ ! -d "$NOTES_DIR" ]]; then
        echo "❌ Notes directory missing: $NOTES_DIR"
        return 1
    fi

    # ----------------------------------
    # Check tables existence
    # ----------------------------------

    tables=$(sqlite3 "$BRAIN_DB" \
        "SELECT name FROM sqlite_master WHERE type='table';")

    for t in notes tags note_tags notes_fts; do
        if ! echo "$tables" | grep -qx "$t"; then
            echo "❌ Table '$t' missing"
            return 1
        fi
    done

    # ----------------------------------
    # Integrity check
    # ----------------------------------

    integrity=$(sqlite3 "$BRAIN_DB" "PRAGMA integrity_check;")

    if [[ "$integrity" != "ok" ]]; then
        echo "❌ Database integrity check failed:"
        echo "$integrity"
        return 1
    fi

    echo "🧠 Brain status: HEALTHY"
    return 0
}
