#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Stats Command
# ==========================================================

cmd_stats() {

    [[ -f "$BRAIN_DB" ]] || {
        log_error "Brain DB not found: $BRAIN_DB"
        return 1
    }

    log_info "Collecting Brain statistics..."

    local notes tags links fts db_size

    notes=$(sqlite3 "$BRAIN_DB" "SELECT COUNT(*) FROM notes;")
    tags=$(sqlite3 "$BRAIN_DB" "SELECT COUNT(*) FROM tags;")
    links=$(sqlite3 "$BRAIN_DB" "SELECT COUNT(*) FROM links;")
    fts=$(sqlite3 "$BRAIN_DB" "SELECT COUNT(*) FROM notes_fts;")
    db_size=$(du -h "$BRAIN_DB" | awk '{print $1}')

    echo "----------------------------------"
    echo "Brain Statistics"
    echo "----------------------------------"
    echo "Notes      : $notes"
    echo "Tags       : $tags"
    echo "Links      : $links"
    echo "FTS rows   : $fts"
    echo "DB size    : $db_size"
    echo "----------------------------------"
}
