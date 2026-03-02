cmd_doctor() {

    echo "[Brain] Running diagnostics..."

    [ ! -f "$BRAIN_DB" ] && { echo "❌ Database missing"; exit 1; }
    [ ! -d "$NOTES_DIR" ] && { echo "❌ Notes directory missing"; exit 1; }

    tables=$(sqlite3 "$BRAIN_DB" ".tables")

    for t in notes tags note_tags notes_fts; do
        echo "$tables" | grep -q "$t" || { echo "❌ Table '$t' missing"; exit 1; }
    done

    echo "🧠 Brain status: HEALTHY"
}
