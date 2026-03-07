#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Doctor Command
# ==========================================================

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

    echo "✅ Database present"
    echo "✅ Notes directory present"

    # ----------------------------------
    # Check tables existence (safe timeout)
    # ----------------------------------

    tables=$(sqlite3 -batch "$BRAIN_DB" -cmd ".timeout 5000" \
        "SELECT name FROM sqlite_master WHERE type='table';" 2>/dev/null)

    for t in notes tags note_tags notes_fts; do
        if ! echo "$tables" | grep -qx "$t"; then
            echo "❌ Table '$t' missing"
            return 1
        fi
    done

    echo "✅ Schema OK"

    # ----------------------------------
    # Integrity check (WAL-safe)
    # ----------------------------------

    integrity=$(sqlite3 -batch "$BRAIN_DB" -cmd ".timeout 5000" \
        "PRAGMA integrity_check;" 2>/dev/null)

    if [[ "$integrity" == "ok" ]]; then
        echo "✅ Integrity check: OK"
    else
        echo "❌ Integrity check failed"
        echo "Details: $integrity"
        echo "🧠 Brain status: CORRUPTED"
        return 1
    fi

    echo "🧠 Brain status: HEALTHY"
    return 0
}
