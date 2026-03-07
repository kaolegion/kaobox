#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox Brain — Health Command (Observability)
# ----------------------------------------------------------
# Aggregates key runtime metrics (read-only)
# - Deterministic output
# - No DB writes
# ==========================================================

[[ -n "${BRAIN_HEALTH_CMD_LOADED:-}" ]] && return 0
readonly BRAIN_HEALTH_CMD_LOADED=1

cmd_health() {

    [[ -n "${BRAIN_DB:-}" ]] || { echo "[ERROR] BRAIN_DB not defined" >&2; return 1; }
    [[ -f "$BRAIN_DB" ]]     || { echo "[ERROR] DB not found: $BRAIN_DB" >&2; return 1; }

    local wal="$BRAIN_DB-wal"
    local shm="$BRAIN_DB-shm"

    echo "BRAIN HEALTH"
    echo "----------------------------------------"

    # Counts (read-only)
    local notes tags links fts
    notes="$(sqlite3 "$BRAIN_DB" "SELECT COUNT(*) FROM notes;" 2>/dev/null || echo 0)"
    tags="$(sqlite3 "$BRAIN_DB"  "SELECT COUNT(*) FROM tags;" 2>/dev/null || echo 0)"
    links="$(sqlite3 "$BRAIN_DB" "SELECT COUNT(*) FROM links;" 2>/dev/null || echo 0)"
    fts="$(sqlite3 "$BRAIN_DB"   "SELECT COUNT(*) FROM notes_fts;" 2>/dev/null || echo 0)"

    echo "Notes indexed     : $notes"
    echo "Tags              : $tags"
    echo "Links (edges)     : $links"
    echo "FTS rows          : $fts"
    echo

    # Sizes in bytes (deterministic)
    local db_size wal_size shm_size
    db_size="$(stat -c%s "$BRAIN_DB" 2>/dev/null || echo 0)"
    wal_size=0
    shm_size=0
    [[ -f "$wal" ]] && wal_size="$(stat -c%s "$wal" 2>/dev/null || echo 0)"
    [[ -f "$shm" ]] && shm_size="$(stat -c%s "$shm" 2>/dev/null || echo 0)"

    echo "DB size (bytes)   : $db_size"
    echo "WAL size (bytes)  : $wal_size"
    echo "SHM size (bytes)  : $shm_size"
    echo

    # Integrity (read-only, bounded)
    local ok
    ok="$(sqlite3 "$BRAIN_DB" "PRAGMA integrity_check;" 2>/dev/null | head -n1 || true)"

    if [[ "$ok" == "ok" ]]; then
        echo "Integrity         : OK"
    else
        echo "Integrity         : FAIL"
        [[ -n "$ok" ]] && echo "Details           : $ok"
        return 1
    fi

    return 0
}
