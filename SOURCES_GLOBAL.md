#!/usr/bin/env bash
set -e

source core/logger.sh

echo "Testing logger..."

log_info "Info OK"
log_warn "Warn OK"
log_error "Error OK"
log_debug "Debug OK"

echo "Logger test complete."
#!/usr/bin/env bash

# ==========================================
# KAOBOX MEMORY MODULE TEST
# Transactional Index Validation
# ==========================================

set -euo pipefail

trap 'echo "[FAIL] Unexpected error"; rm -f "$TEST_FILE"' ERR

echo "[TEST] Starting memory index test"

# ------------------------------------------
# Resolve runtime paths
# ------------------------------------------

: "${BRAIN_ROOT:=/data/brain}"

BRAIN_DB="$BRAIN_ROOT/.index/brain.db"
TEST_FILE="$BRAIN_ROOT/notes/__test_memory__.md"

# ------------------------------------------
# Preflight checks
# ------------------------------------------

[[ -f "$BRAIN_DB" ]] || {
  echo "[FAIL] Database not found"
  exit 1
}

mkdir -p "$(dirname "$TEST_FILE")"

# ------------------------------------------
# Create test note
# ------------------------------------------

cat > "$TEST_FILE" <<EOF
# Test Memory Module

Tags: #alpha #beta

This is a test note for index validation.
EOF

echo "[TEST] Test file created"

# ------------------------------------------
# Run reindex via CLI (architecture aligned)
# ------------------------------------------

brain reindex

echo "[TEST] Reindex executed"

# ------------------------------------------
# Validate note insertion
# ------------------------------------------

SAFE_PATH=$(printf "%s" "$TEST_FILE" | sed "s/'/''/g")

NOTE_EXISTS=$(sqlite3 "$BRAIN_DB" \
  "SELECT COUNT(*) FROM notes WHERE path = '$SAFE_PATH';")

if [[ "$NOTE_EXISTS" != "1" ]]; then
  echo "[FAIL] Note not inserted correctly"
  exit 1
fi

echo "[PASS] Note inserted"

# ------------------------------------------
# Validate tag linkage
# ------------------------------------------

TAG_COUNT=$(sqlite3 "$BRAIN_DB" "
SELECT COUNT(*)
FROM tags t
JOIN note_tags nt ON t.id = nt.tag_id
JOIN notes n ON nt.note_id = n.id
WHERE n.path = '$SAFE_PATH';
")

if [[ "$TAG_COUNT" != "2" ]]; then
  echo "[FAIL] Tags not linked correctly"
  exit 1
fi

echo "[PASS] Tags linked"

# ------------------------------------------
# Cleanup (transactional)
# ------------------------------------------

sqlite3 "$BRAIN_DB" <<SQL
BEGIN;
DELETE FROM note_tags WHERE note_id IN (
  SELECT id FROM notes WHERE path = '$TEST_FILE'
);
DELETE FROM notes WHERE path = '$TEST_FILE';
COMMIT;
SQL

rm -f "$TEST_FILE"

echo "[TEST] Cleanup done"
echo "[SUCCESS] Memory index test completed"
#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Engine FTS Layer (v2.5 Simple)
# ----------------------------------------------------------
# Emits SQL only.
# Uses SELECT id internally (path is UNIQUE).
# Must be executed inside an active transaction.
# ==========================================================

fts_sql() {
    local path="$1"
    local title="$2"
    local content="$3"

    local escaped_path
    escaped_path="$(sql_escape "$path")"

    cat <<SQL
-- Remove existing FTS row
DELETE FROM notes_fts
WHERE rowid = (SELECT id FROM notes WHERE path='$escaped_path');

-- Insert updated FTS content
INSERT INTO notes_fts(rowid, title, content)
VALUES (
    (SELECT id FROM notes WHERE path='$escaped_path'),
    '$(sql_escape "$title")',
    '$(sql_escape "$content")'
);
SQL
}
#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Engine Links Layer (v2.5 Simple)
# ----------------------------------------------------------
# Emits SQL only.
# Uses SELECT id internally.
# Must run inside active transaction.
# ==========================================================

extract_links() {
    grep -oE '\[\[[^]]+\]\]' "$1" \
        | sed 's/\[\[//;s/\]\]//' \
        | sort -u
}

links_sql() {
    local path="$1"
    local file="$2"

    local source_id="(SELECT id FROM notes WHERE path='$(sql_escape "$path")')"

    echo "DELETE FROM links WHERE source_id = $source_id;"

    while IFS= read -r target; do
        [[ -z "$target" ]] && continue

        cat <<SQL
INSERT OR IGNORE INTO links(source_id, target_id)
VALUES (
    $source_id,
    (SELECT id FROM notes WHERE title='$(sql_escape "$target")')
);
SQL
    done < <(extract_links "$file")
}
#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Engine Metadata Layer (v2.5)
# ----------------------------------------------------------
# Emits SQL only.
# No direct sqlite3 calls.
# Orchestrator manages execution & transactions.
# ==========================================================
metadata_sql() {
    local path="$1"
    local title="$2"
    local hash="$3"
    local mtime="$4"
    local size="$5"

    cat <<SQL
INSERT INTO notes (path, title, updated_at, content_hash, file_mtime, file_size)
VALUES (
    '$(sql_escape "$path")',
    '$(sql_escape "$title")',
    datetime('now'),
    '$hash',
    $mtime,
    $size
)
ON CONFLICT(path) DO UPDATE SET
    title=excluded.title,
    updated_at=datetime('now'),
    content_hash=excluded.content_hash,
    file_mtime=excluded.file_mtime,
    file_size=excluded.file_size;
SQL
}
#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Engine Tags Layer (v2.5 Simple)
# ----------------------------------------------------------
# Emits SQL only.
# Uses SELECT id internally.
# Must run inside active transaction.
# ==========================================================

# Extract hashtags: #tag
extract_tags() {
    grep -oE '#[A-Za-z0-9_-]+' "$1" \
        | sed 's/^#//' \
        | sort -u
}

tags_sql() {
    local path="$1"
    local file="$2"

    local note_id="(SELECT id FROM notes WHERE path='$(sql_escape "$path")')"

    # Clear previous tag relations
    echo "DELETE FROM note_tags WHERE note_id = $note_id;"

    while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue

        cat <<SQL
-- Ensure tag exists
INSERT OR IGNORE INTO tags(name)
VALUES ('$(sql_escape "$tag")');

-- Link tag to note
INSERT OR IGNORE INTO note_tags(note_id, tag_id)
VALUES (
    $note_id,
    (SELECT id FROM tags WHERE name='$(sql_escape "$tag")')
);
SQL
    done < <(extract_tags "$file")
}
#!/usr/bin/env bash
# ==========================================================
# KAOBOX - Memory Engine Transaction Layer (v2.5)
# ----------------------------------------------------------
# Emits SQL only. Never calls sqlite3 directly.
# Orchestrator is responsible for piping to sqlite3.
# ==========================================================

begin_tx() {
    echo "PRAGMA foreign_keys=ON;"
    echo "BEGIN IMMEDIATE;"
}

commit_tx() {
    echo "COMMIT;"
}

rollback_tx() {
    echo "ROLLBACK;"
}
# ==========================================================
# KAOBOX - File Analysis Helper (v3 Hardened)
# ==========================================================

analyze_file() {
    local file="$1"

    require_file "$file" || return 1

    unset FILE_TITLE FILE_HASH FILE_MTIME FILE_SIZE FILE_CONTENT

    FILE_TITLE="$(extract_title "$file")" || return 1
    FILE_HASH="$(compute_hash "$file")" || return 1
    FILE_MTIME="$(file_mtime "$file")" || return 1
    FILE_SIZE="$(file_size "$file")" || return 1
    FILE_CONTENT="$(cat "$file")" || return 1
}

# ==========================================================
# Validation helpers
# ==========================================================

require_absolute() {
    local path="$1"
    [[ "$path" = /* ]] || {
        echo "[Memory][ERROR] Path must be absolute: $path" >&2
        return 1
    }
}

require_file() {
    local path="$1"
    [[ -f "$path" ]] || {
        echo "[Memory][ERROR] File not found: $path" >&2
        return 1
    }
}

# ==========================================================
# File helpers
# ==========================================================

extract_title() {
    grep -m1 '^# ' "$1" | sed 's/^# //'
}

compute_hash() {
    sha256sum "$1" | awk '{print $1}'
}

file_mtime() {
    stat -c %Y "$1"
}

file_size() {
    stat -c %s "$1"
}

# ==========================================================
# SQL escape
# ==========================================================

sql_escape() {
    printf "%s" "$1" | sed "s/'/''/g"
}
#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Memory Garbage Collector (v2.6)
# ----------------------------------------------------------
# - Emits SQL only
# - No transaction control (handled by index.sh)
# - Safe against accidental full wipe
# - Cleans:
#     * Deleted notes
#     * Orphan note_tags
#     * Orphan links
#     * Unused tags
#     * Orphan FTS rows
# ==========================================================

gc_sql() {
    local notes_dir="$1"

    # Safety: directory must exist
    [[ -d "$notes_dir" ]] || {
        echo "[Memory][GC] Invalid notes directory: $notes_dir" >&2
        exit 1
    }

    # Collect existing markdown files
    local existing_paths=()
    while IFS= read -r file; do
        existing_paths+=("'$(sql_escape "$file")'")
    done < <(find "$notes_dir" -type f -name "*.md")

    # Build NOT IN clause safely
    local path_clause
    if [[ ${#existing_paths[@]} -eq 0 ]]; then
        # No files found → delete all notes
        path_clause="1=1"
    else
        path_clause="path NOT IN ($(IFS=,; echo "${existing_paths[*]}"))"
    fi

    cat <<SQL

-- =========================================================
-- Remove deleted notes
-- =========================================================
DELETE FROM notes WHERE $path_clause;

-- =========================================================
-- Clean orphan note_tags
-- =========================================================
DELETE FROM note_tags
WHERE note_id NOT IN (SELECT id FROM notes);

-- =========================================================
-- Clean orphan links
-- =========================================================
DELETE FROM links
WHERE source_id NOT IN (SELECT id FROM notes)
   OR target_id NOT IN (SELECT id FROM notes);

-- =========================================================
-- Clean unused tags
-- =========================================================
DELETE FROM tags
WHERE id NOT IN (SELECT tag_id FROM note_tags);

-- =========================================================
-- Clean orphan FTS rows
-- =========================================================
DELETE FROM notes_fts
WHERE rowid NOT IN (SELECT id FROM notes);

SQL
}
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

source "$ENGINE/utils.sh"
source "$ENGINE/tx.sh"
source "$ENGINE/metadata.sh"
source "$ENGINE/fts.sh"
source "$ENGINE/tags.sh"
source "$ENGINE/links.sh"
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

    local file="$1"

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
#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# KAOBOX MEMORY MODULE
# File: init.sh
# Purpose: Initialize Brain structure (Markdown + SQLite)
#
# Guarantees:
#   - Idempotent schema
#   - Foreign keys enforced
#   - FTS rowid bound to notes.id
#   - Production safe
#
# Version: Brain v2.6 Stable
# =========================================================

# Environment must be injected by dispatcher

[[ -n "${BRAIN_DB:-}" ]] || {
    echo "[Memory][ERROR] Environment not initialized (BRAIN_DB missing)"
    exit 1
}

[[ -n "${BRAIN_ROOT:-}" ]] || {
    echo "[Memory][ERROR] BRAIN_ROOT not defined"
    exit 1
}

[[ -n "${INDEX_DIR:-}" ]] || {
    echo "[Memory][ERROR] INDEX_DIR not defined"
    exit 1
}

[[ -n "${BRAIN_DB:-}" ]] || {
    echo "[Memory][ERROR] BRAIN_DB not defined"
    exit 1
}

echo "[Memory] Ensuring brain directory structure..."

mkdir -p "$BRAIN_ROOT/inbox"
mkdir -p "$BRAIN_ROOT/notes"
mkdir -p "$BRAIN_ROOT/projects"
mkdir -p "$BRAIN_ROOT/archive"
mkdir -p "$INDEX_DIR"

# =========================================================
# SQLITE INITIALIZATION
# =========================================================

sqlite3 "$BRAIN_DB" <<'SQL'

PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA foreign_keys=ON;
PRAGMA busy_timeout=5000;
PRAGMA journal_size_limit=10485760;

-- =====================================================
-- CORE NOTES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY,
    path TEXT UNIQUE NOT NULL,
    title TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT,
    content_hash TEXT,
    file_mtime INTEGER,
    file_size INTEGER
);

CREATE INDEX IF NOT EXISTS idx_notes_title ON notes(title);

-- =====================================================
-- FTS5 VIRTUAL TABLE
-- -----------------------------------------------------
-- rowid == notes.id
-- Managed manually by engine (no triggers)
-- =====================================================

CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
    title,
    content
);

-- =====================================================
-- TAGS
-- =====================================================

CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS note_tags (
    note_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (note_id, tag_id),
    FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name);
CREATE INDEX IF NOT EXISTS idx_note_tags_note ON note_tags(note_id);
CREATE INDEX IF NOT EXISTS idx_note_tags_tag ON note_tags(tag_id);

-- =====================================================
-- LINKS (Graph Layer)
-- =====================================================

CREATE TABLE IF NOT EXISTS links (
    source_id INTEGER NOT NULL,
    target_id INTEGER NOT NULL,
    PRIMARY KEY (source_id, target_id),
    FOREIGN KEY (source_id) REFERENCES notes(id) ON DELETE CASCADE,
    FOREIGN KEY (target_id) REFERENCES notes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_links_source ON links(source_id);
CREATE INDEX IF NOT EXISTS idx_links_target ON links(target_id);

SQL

echo "[Memory] Initialization complete (v2.6)."
#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox - Memory Query Engine (Hardened V1)
# ----------------------------------------------------------
# - Idempotent
# - No exit
# - Safe LIMIT
# - Consistent output
# ==========================================================

[[ -n "${BRAIN_QUERY_LOADED:-}" ]] && return 0
readonly BRAIN_QUERY_LOADED=1

DEFAULT_LIMIT=20

# ----------------------------------------------------------
# Internal SQLite wrapper
# ----------------------------------------------------------

_sqlite_exec() {
    sqlite3 -batch -noheader -separator $'\t' "$BRAIN_DB"
}

# ----------------------------------------------------------
# Utility: sanitize LIMIT (integer only)
# ----------------------------------------------------------

_sanitize_limit() {
    local value="$1"

    [[ "$value" =~ ^[0-9]+$ ]] || value="$DEFAULT_LIMIT"
    printf "%s" "$value"
}

# ----------------------------------------------------------
# FTS Query
# ----------------------------------------------------------

query_fts() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined"
        return 1
    }

    local q="$1"
    local limit
    limit="$(_sanitize_limit "${2:-$DEFAULT_LIMIT}")"

    [[ -z "$q" ]] && {
        echo "[Query] Empty search query"
        return 1
    }

    _sqlite_exec <<SQL
.parameter init
.parameter set @q "$q"
SELECT n.id,
       n.path,
       n.title,
       bm25(notes_fts) AS score
FROM notes_fts
JOIN notes n ON n.rowid = notes_fts.rowid
WHERE notes_fts MATCH @q
ORDER BY score
LIMIT $limit;
SQL
}

# ----------------------------------------------------------
# Tag Query
# ----------------------------------------------------------

query_by_tag() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined"
        return 1
    }

    local tag="$1"
    local limit
    limit="$(_sanitize_limit "${2:-50}")"

    [[ -z "$tag" ]] && {
        echo "[Query] Empty tag"
        return 1
    }

    _sqlite_exec <<SQL
.parameter init
.parameter set @tag "$tag"
SELECT n.id,
       n.path,
       n.title,
       NULL as score
FROM notes n
JOIN note_tags nt ON n.id = nt.note_id
JOIN tags t ON t.id = nt.tag_id
WHERE t.name = @tag
ORDER BY n.updated_at DESC
LIMIT $limit;
SQL
}

# ----------------------------------------------------------
# Backlinks Query
# ----------------------------------------------------------

query_backlinks() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined"
        return 1
    }

    local path="$1"

    [[ -z "$path" ]] && {
        echo "[Query] Missing path"
        return 1
    }

    _sqlite_exec <<SQL
.parameter init
.parameter set @path "$path"
SELECT src.id,
       src.path,
       src.title,
       NULL as score
FROM links l
JOIN notes src ON src.id = l.source_id
JOIN notes tgt ON tgt.id = l.target_id
WHERE tgt.path = @path;
SQL
}
#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Context Command Layer
# ----------------------------------------------------------
# Layer: Cognitive (Kernel Extension)
# Depends on: context/{resolver,scorer,session}
# ==========================================================

# ----------------------------------------------------------
# Prevent double load
# ----------------------------------------------------------
[[ -n "${BRAIN_CONTEXT_CMD_LOADED:-}" ]] && return 0
readonly BRAIN_CONTEXT_CMD_LOADED=1

# ----------------------------------------------------------
# Load Context Layer (Kernel level)
# ----------------------------------------------------------
source "$KAOBOX_ROOT/lib/brain/context/resolver.sh"
source "$KAOBOX_ROOT/lib/brain/context/scorer.sh"
source "$KAOBOX_ROOT/lib/brain/context/session.sh"

# ==========================================================
# Command: brain context
# ==========================================================

cmd_context() {

    local file="$1"

    [[ -z "$file" ]] && {
        log_error "Usage: brain context <file>"
        return 1
    }

    [[ -f "$file" ]] || {
        log_error "File not found: $file"
        return 1
    }

    log_info "[context] Resolving for $file"

    set -o pipefail

    resolve_context "$file" \
        | score_context \
        | head -10 \
        | while IFS="|" read -r score path; do
            printf "[%2s] %s\n" "$score" "$path"
        done

    local status=$?
    set +o pipefail

    return $status
}

# ==========================================================
# Command: brain focus
# ==========================================================

cmd_focus() {

    local file="$1"

    [[ -z "$file" ]] && {
        log_error "Usage: brain focus <file>"
        return 1
    }

    [[ -f "$file" ]] || {
        log_error "File not found: $file"
        return 1
    }

    session_set_active "$file"
    log_info "[context] Focused on: $file"

    cmd_context "$file"
}
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
cmd_fuzzy() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[ERROR] BRAIN_DB not defined"
        return 1
    }

    command -v fzf >/dev/null 2>&1 || {
        echo "[ERROR] fzf not installed"
        return 1
    }

    local selected
    selected=$(
        sqlite3 -separator "|" "$BRAIN_DB" "
        SELECT n.id,
               n.title,
               n.updated_at,
               IFNULL((
                   SELECT GROUP_CONCAT('#' || t2.name, ' ')
                   FROM (
                       SELECT t2.name
                       FROM note_tags nt2
                       JOIN tags t2 ON t2.id = nt2.tag_id
                       WHERE nt2.note_id = n.id
                       ORDER BY t2.name
                   )
               ), '')
        FROM notes n
        ORDER BY n.updated_at DESC;
        " | while IFS="|" read -r id title date tags; do
            printf "%s|%-30s | %s | %s\n" "$id" "$title" "$date" "$tags"
        done | fzf \
            --delimiter="|" \
            --layout=reverse \
            --height=90% \
            --border \
            --prompt="🧠 Brain > "
    )

    [[ -z "$selected" ]] && return 0

    local note_id
    note_id=$(echo "$selected" | cut -d'|' -f1)

    # Validate numeric id
    [[ "$note_id" =~ ^[0-9]+$ ]] || {
        echo "[ERROR] Invalid selection"
        return 1
    }

    local filepath
    filepath=$(sqlite3 "$BRAIN_DB" "
        SELECT path FROM notes WHERE id=$note_id LIMIT 1;
    ")

    if [[ -z "$filepath" || ! -f "$filepath" ]]; then
        echo "[ERROR] File missing on disk."
        return 1
    fi

    "${EDITOR:-micro}" "$filepath"
}
cmd_ls() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[ERROR] BRAIN_DB not defined"
        return 1
    }

    local query
    query="
        SELECT n.id,
               n.title,
               n.updated_at,
               IFNULL((
                   SELECT GROUP_CONCAT(name, ',')
                   FROM (
                       SELECT t2.name
                       FROM note_tags nt2
                       JOIN tags t2 ON t2.id = nt2.tag_id
                       WHERE nt2.note_id = n.id
                       ORDER BY t2.name
                   )
               ), '')
        FROM notes n
        ORDER BY n.updated_at DESC;
    "

    local count=0

    while IFS=$'\t' read -r id title date tags; do
        count=$((count+1))
        printf "\n%s\n" "$title"
        printf "Date: %s\n" "$date"
        [[ -n "$tags" ]] && printf "Tags: %s\n" "$tags"
        printf "%s\n" "----------------------------------------"
    done < <(
        sqlite3 -separator $'\t' "$BRAIN_DB" "$query"
    )

    if [[ $count -eq 0 ]]; then
        echo "[Brain] No notes indexed."
    fi
}
cmd_new() {

    [[ -n "${NOTES_DIR:-}" ]] || {
        log_error "NOTES_DIR not defined"
        return 1
    }

    [[ $# -lt 1 ]] && {
        usage
        return 1
    }

    local title="$1"

    # ------------------------------------------------------
    # Slug generation
    # ------------------------------------------------------

    local slug
    slug=$(printf "%s" "$title" \
        | tr '[:upper:]' '[:lower:]' \
        | tr ' ' '-' \
        | tr -cd 'a-z0-9-_')

    [[ -z "$slug" ]] && {
        log_error "Invalid title"
        return 1
    }

    local filepath="$NOTES_DIR/$slug.md"

    # ------------------------------------------------------
    # Prevent overwrite
    # ------------------------------------------------------

    if [[ -f "$filepath" ]]; then
        log_error "Note already exists: $filepath"
        return 1
    fi

    # ------------------------------------------------------
    # Create file
    # ------------------------------------------------------

    cat > "$filepath" <<EOF
# $title

Tags: #

Résumé:

---

EOF

    # ------------------------------------------------------
    # Indexing (transactional)
    # ------------------------------------------------------

    acquire_lock || {
        log_error "Could not acquire lock"
        rm -f "$filepath"
        return 1
    }

    safe_source "$MEMORY_INDEX"

    if ! index_note "$filepath"; then
        log_error "Indexing failed. Rolling back file."
        rm -f "$filepath"
        release_lock
        return 1
    fi

    release_lock

    log_info "Note created and indexed: $filepath"
}
cmd_open() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[ERROR] BRAIN_DB not defined"
        return 1
    }

    if [[ $# -lt 1 ]]; then
        usage
        return 1
    fi

    local raw_filename="$1"

    # Escape single quotes safely
    local filename_safe
    filename_safe="$(printf "%s" "$raw_filename" | sed "s/'/''/g")"

    local query="
        SELECT path
        FROM notes
        WHERE path LIKE '%' || '$filename_safe' || '%'
        ORDER BY updated_at DESC
        LIMIT 1;
    "

    local filepath
    filepath=$(sqlite3 "$BRAIN_DB" "$query")

    if [[ -z "$filepath" ]]; then
        echo "Note not found."
        return 1
    fi

    if [[ ! -f "$filepath" ]]; then
        echo "File missing on disk: $filepath"
        return 1
    fi

    "${EDITOR:-micro}" "$filepath"
}
#!/usr/bin/env bash

# ==========================================
# KAOBOX BRAIN — REINDEX COMMAND
# Batch rebuild (single transaction)
# ==========================================

set -euo pipefail


#!/usr/bin/env bash
# ------------------------------------------
# Security — Absolute path guard
# ------------------------------------------

_check_absolute_path() {
    local path="$1"
    [[ "$path" == /* ]] || {
        echo "[ERROR] Absolute path required: $path"
        return 1
    }
}

# ------------------------------------------
# Command implementation
# ------------------------------------------

cmd_reindex() {

    [[ -n "${NOTES_DIR:-}" ]] || {
        echo "[ERROR] NOTES_DIR not defined"
        return 1
    }

    _check_absolute_path "$NOTES_DIR" || return 1

    if [[ ! -d "$NOTES_DIR" ]]; then
        echo "[ERROR] Notes directory missing: $NOTES_DIR"
        return 1
    fi

    echo "[Brain] Reindexing all notes..."

    mapfile -d '' files < <(
        find "$NOTES_DIR" -type f -name "*.md" -print0 | sort -z
    )

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "[Brain] No notes found."
        return 0
    fi

    acquire_lock || {
      echo "❌ Could not acquire lock"
      return 1
    }
    
    reindex_all "${files[@]}"
    
    release_lock

    echo "[Brain] Reindex complete."
    echo "[Brain] Files processed: ${#files[@]}"
}
cmd_search() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[ERROR] BRAIN_DB not defined"
        return 1
    }

    [[ $# -lt 1 ]] && {
        usage
        return 1
    }

    local mode="table"
    local limit=""
    local args=()

    # ------------------------------------------------------
    # Parse flags
    # ------------------------------------------------------

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                mode="json"
                shift
                ;;
            --raw)
                mode="raw"
                shift
                ;;
            --limit=*)
                limit="${1#--limit=}"
                shift
                ;;
            --limit)
                limit="$2"
                shift 2
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done

    local raw_query="${args[*]}"

    [[ -z "$raw_query" ]] && {
        echo "Empty query."
        return 1
    }

    log INFO "Search query: $raw_query | mode=$mode | limit=${limit:-default}"

    # ------------------------------------------------------
    # Execute query and capture results
    # ------------------------------------------------------

    local results=()

    if [[ "$raw_query" == tag:* ]]; then

        local tag="${raw_query#tag:}"
        [[ -z "$tag" ]] && { echo "Empty tag."; return 1; }

        if ! mapfile -t results < <(query_by_tag "$tag" "${limit:-}"); then
            echo "[ERROR] Tag query failed"
            return 1
        fi

    elif [[ "$raw_query" == backlinks:* ]]; then

        local path="${raw_query#backlinks:}"
        [[ -z "$path" ]] && { echo "Empty backlink path."; return 1; }

        if ! mapfile -t results < <(query_backlinks "$path"); then
            echo "[ERROR] Backlink query failed"
            return 1
        fi

    else

        if ! mapfile -t results < <(query_fts "$raw_query" "${limit:-}"); then
            echo "[ERROR] FTS query failed"
            return 1
        fi

    fi

    # ------------------------------------------------------
    # Render output
    # ------------------------------------------------------

    render_results "$mode" "${results[@]}"
}
#!/usr/bin/env bash
# ==========================================================
# KAOBOX - Status Command
# ----------------------------------------------------------
# Displays Brain system health and environment state
# ==========================================================

cmd_status() {

    log_info "KaoBox Brain Status"

    echo "----------------------------------------"
    echo "KAOBOX_ROOT : $KAOBOX_ROOT"
    echo "BRAIN_ROOT  : $BRAIN_ROOT"
    echo "BRAIN_DB    : $BRAIN_DB"
    echo "LOG_DIR     : $LOG_DIR"
    echo "Log Level   : ${KAOBOX_LOG_LEVEL:-INFO}"
    echo "----------------------------------------"

    if [[ -f "$BRAIN_DB" ]]; then
        log_info "Brain DB detected."
    else
        log_warn "Brain DB not found."
    fi

    echo "System OK"
}
#!/usr/bin/env bash
set -euo pipefail

[[ -n "${BRAIN_THINK_CMD_LOADED:-}" ]] && return 0
readonly BRAIN_THINK_CMD_LOADED=1

safe_source "$KAOBOX_ROOT/lib/brain/think/engine.sh"

cmd_think() {

    local query="$*"

    [[ -z "$query" ]] && {
        log_error "Usage: brain think <query>"
        return 1
    }

    log_info "[think] Query: $query"

    think_engine_run "$query"
}
#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Context Resolver
# ----------------------------------------------------------
# Layer: Cognitive
# Responsibility:
#   - Retrieve context candidates from memory graph
#   - Output: path|layer|updated_at
# Depends on:
#   - BRAIN_DB
# ==========================================================
# TODO:
# - Add configuration support
# - Add adaptive learning weights
# - Add telemetry hooks
# ----------------------------------------------------------
# Prevent double load
# ----------------------------------------------------------
[[ -n "${BRAIN_CONTEXT_RESOLVER_LOADED:-}" ]] && return 0
readonly BRAIN_CONTEXT_RESOLVER_LOADED=1

# ==========================================================
# Function: resolve_context
# ==========================================================

resolve_context() {

    local file="$1"

    [[ -f "${file:-}" ]] || {
        log_error "[context] File not found: $file"
        return 1
    }

    [[ -n "${BRAIN_DB:-}" && -f "$BRAIN_DB" ]] || {
        log_error "[context] BRAIN_DB not available"
        return 1
    }

    # ------------------------------------------------------
    # Escape path safely
    # ------------------------------------------------------
    local safe_file
    safe_file=${file//\'/\'\'}

    # ------------------------------------------------------
    # Retrieve note ID
    # ------------------------------------------------------
    local note_id
    note_id=$(sqlite3 "$BRAIN_DB" \
        "SELECT id FROM notes WHERE path='$safe_file';")

    [[ -z "${note_id:-}" || ! "$note_id" =~ ^[0-9]+$ ]] && {
        log_warn "[context] Note not indexed: $file"
        return 1
    }

    local SEP="|"

    # ------------------------------------------------------
    # GRAPH_OUT
    # ------------------------------------------------------
    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT n2.path, 'GRAPH_OUT', n2.updated_at
        FROM links l
        JOIN notes n2 ON l.target_id = n2.id
        WHERE l.source_id = $note_id;
    "

    # ------------------------------------------------------
    # GRAPH_IN
    # ------------------------------------------------------
    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT n2.path, 'GRAPH_IN', n2.updated_at
        FROM links l
        JOIN notes n2 ON l.source_id = n2.id
        WHERE l.target_id = $note_id;
    "

    # ------------------------------------------------------
    # RECENT
    # ------------------------------------------------------
    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT path, 'RECENT', updated_at
        FROM notes
        WHERE id != $note_id
        ORDER BY updated_at DESC
        LIMIT 5;
    "

    # ------------------------------------------------------
    # SELF
    # ------------------------------------------------------
    sqlite3 -separator "$SEP" "$BRAIN_DB" "
        SELECT path, 'SELF', updated_at
        FROM notes
        WHERE id = $note_id;
    "
}
#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Context Scorer
# ----------------------------------------------------------
# Layer: Cognitive
# Responsibility:
#   - Score context candidates
#   - Apply temporal decay
#   - Apply session boost
# ==========================================================
# TODO:
# - Add configuration support
# - Add adaptive learning weights
# - Add telemetry hooks
# ----------------------------------------------------------
# Prevent double load
# ----------------------------------------------------------
[[ -n "${BRAIN_CONTEXT_SCORER_LOADED:-}" ]] && return 0
readonly BRAIN_CONTEXT_SCORER_LOADED=1

# ----------------------------------------------------------
# Load local dependencies (same layer only)
# ----------------------------------------------------------
CONTEXT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CONTEXT_DIR/session.sh"

# ==========================================================
# Function: score_context
# ==========================================================

score_context() {

    declare -A scores
    declare -A last_update

    local now
    now=$(date +%s)

    while IFS="|" read -r path layer updated_at; do
        [[ -z "${path:-}" ]] && continue

        # --------------------------------------------------
        # Base weight per layer
        # --------------------------------------------------
        local base=0
        case "$layer" in
            SELF)      base=4 ;;
            GRAPH_OUT) base=3 ;;
            GRAPH_IN)  base=2 ;;
            RECENT)    base=1 ;;
        esac

        (( base == 0 )) && continue

        local current=${scores["$path"]:-0}
        local decay=100

        # --------------------------------------------------
        # Temporal Decay
        # --------------------------------------------------
        if [[ -n "${updated_at:-}" ]]; then
            local updated
            updated=$(date -d "$updated_at" +%s 2>/dev/null || echo 0)

            if (( updated > 0 )); then
                local age_days=$(( (now - updated) / 86400 ))

                if   (( age_days <= 1 ));  then decay=100
                elif (( age_days <= 7 ));  then decay=70
                elif (( age_days <= 30 )); then decay=40
                else                            decay=20
                fi
            fi
        fi

        local weighted=$(( base * decay / 100 ))

        scores["$path"]=$(( current + weighted ))
        last_update["$path"]="$updated_at"

    done

    # ------------------------------------------------------
    # Session Boost
    # ------------------------------------------------------
    local active
    active=$(session_get_active || true)

    for path in "${!scores[@]}"; do
        local total=${scores[$path]}

        if [[ -n "${active:-}" && "$path" == "$active" ]]; then
            total=$(( total + 5 ))
        fi

        printf "%s|%s\n" "$total" "$path"
    done | sort -t'|' -nr
}
#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Context Session Manager
# ----------------------------------------------------------
# Layer: Cognitive
# Responsibility:
#   - Manage active context session
# Storage:
#   - $BRAIN_ROOT/.session
# ==========================================================
# TODO:
# - Add configuration support
# - Add adaptive learning weights
# - Add telemetry hooks
# ----------------------------------------------------------
# Prevent double load
# ----------------------------------------------------------
[[ -n "${BRAIN_CONTEXT_SESSION_LOADED:-}" ]] && return 0
readonly BRAIN_CONTEXT_SESSION_LOADED=1

# ----------------------------------------------------------
# Validate runtime environment
# ----------------------------------------------------------
[[ -n "${BRAIN_ROOT:-}" ]] || {
    echo "[context] BRAIN_ROOT not defined" >&2
    return 1
}

readonly SESSION_FILE="$BRAIN_ROOT/.session"

# ==========================================================
# Set active note
# ==========================================================
session_set_active() {

    local file="$1"

    [[ -n "${file:-}" ]] || return 1

    echo "$file" > "$SESSION_FILE"
}

# ==========================================================
# Get active note
# ==========================================================
session_get_active() {

    [[ -f "$SESSION_FILE" ]] || return 0
    cat "$SESSION_FILE"
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Think Engine (Orchestration Layer v1.1)
# ==========================================================

[[ -n "${BRAIN_THINK_ENGINE_LOADED:-}" ]] && return 0
readonly BRAIN_THINK_ENGINE_LOADED=1

# ----------------------------------------------------------
# Dependencies
# ----------------------------------------------------------

safe_source "$MODULES_ROOT/memory/query.sh"
safe_source "$KAOBOX_ROOT/lib/brain/context/session.sh"
safe_source "$KAOBOX_ROOT/lib/brain/think/ranker.sh"


# ==========================================================
# THINK ENGINE RUNNER
# ==========================================================

think_engine_run() {

    local query="$1"

    [[ -z "$query" ]] && return 0

    # ------------------------------------------------------
    # Active focus (if context available)
    # ------------------------------------------------------
    
    local active_focus=""
    
    if declare -f session_get_active >/dev/null 2>&1; then
        active_focus="$(session_get_active 2>/dev/null || true)"
    fi

    # ------------------------------------------------------
    # FTS retrieval (raw layer)
    # ------------------------------------------------------

    mapfile -t fts_results < <(query_fts "$query" 10)

    [[ ${#fts_results[@]} -eq 0 ]] && {
        echo "No results."
        return 0
    }

    # ------------------------------------------------------
    # Ranking (cognitive layer)
    # ------------------------------------------------------

    think_rank_results "$active_focus" "${fts_results[@]}" \
    | while IFS='|' read -r composite raw; do
        echo "$raw"
      done
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Think Ranker (Composite Scoring v1.2 ready)
# ==========================================================

[[ -n "${BRAIN_THINK_RANKER_LOADED:-}" ]] && return 0
readonly BRAIN_THINK_RANKER_LOADED=1

# ----------------------------------------------------------
# Configurable weights
# ----------------------------------------------------------

: "${THINK_FOCUS_BOOST:=5}"

# ==========================================================
# Helpers
# ==========================================================

_extract_path() {
    # Extract second column safely (tab or space separated)
    local line="$1"

    # Try tab first
    local path
    IFS=$'\t' read -r _ path _ <<< "$line"

    if [[ -n "$path" ]]; then
        printf "%s\n" "$path"
        return
    fi

    # Fallback to space parsing
    printf "%s\n" "$line" | awk '{print $2}'
}

_extract_score() {
    # Extract last field (score)
    printf "%s\n" "$1" | awk '{print $NF}'
}

# ==========================================================
# Ranking Function
# ==========================================================

think_rank_results() {

    local focus="$1"
    shift
    local results=("$@")

    local line id path title raw_score relevance composite

    for line in "${results[@]}"; do

        [[ -z "${line:-}" ]] && continue

        # Safe parsing (TAB separated)
        IFS=$'\t' read -r id path title raw_score <<< "$line"

        # Skip malformed lines
        [[ -z "${path:-}" || -z "${raw_score:-}" ]] && continue

        # Normalize FTS score (bm25 negative → positive relevance)
        relevance=$(awk "BEGIN {print -1 * ($raw_score)}")

        composite="$relevance"

        # Focus boost
        if [[ -n "${focus:-}" && "$path" == "$focus" ]]; then
            composite=$(awk "BEGIN {print $relevance + $THINK_FOCUS_BOOST}")
        fi

        printf "%s|%s\n" "$composite" "$line"

    done | sort -t'|' -k1 -nr
}
#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox Brain - CLI Dispatcher (Kernel v3.0)
# Deterministic • Modular • Safe
# ==========================================================

# ----------------------------------------------------------
# Prevent double loading
# ----------------------------------------------------------

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    [[ -n "${BRAIN_DISPATCHER_LOADED:-}" ]] && return 0
    readonly BRAIN_DISPATCHER_LOADED=1
fi

# ----------------------------------------------------------
# Detect Root
# ----------------------------------------------------------

if [[ -z "${KAOBOX_ROOT:-}" ]]; then
    KAOBOX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
export KAOBOX_ROOT

# ----------------------------------------------------------
# Safe source helper
# ----------------------------------------------------------

safe_source() {
    local file="$1"
    [[ -f "$file" ]] || {
        echo "Fatal: missing file $file"
        exit 1
    }
    # shellcheck source=/dev/null
    source "$file"
}

# ----------------------------------------------------------
# Load Core (ORDER MATTERS)
# ----------------------------------------------------------

safe_source "$KAOBOX_ROOT/lib/brain/env.sh"
safe_source "$KAOBOX_ROOT/core/logger.sh"
safe_source "$KAOBOX_ROOT/lib/brain/preflight.sh"
safe_source "$KAOBOX_ROOT/lib/brain/sanitize.sh"
safe_source "$KAOBOX_ROOT/lib/brain/lock.sh"
safe_source "$KAOBOX_ROOT/lib/brain/renderer.sh"

# ----------------------------------------------------------
# Paths
# ----------------------------------------------------------

readonly COMMANDS_DIR="$KAOBOX_ROOT/lib/brain/commands"
readonly MEMORY_QUERY="$MODULES_ROOT/memory/query.sh"
readonly MEMORY_INDEX="$MODULES_ROOT/memory/index.sh"

# ----------------------------------------------------------
# Usage
# ----------------------------------------------------------

usage() {
cat <<EOF
🧠 KaoBox Brain CLI

Usage:
  brain status
  brain doctor
  brain new "Title"
  brain search <query>
  brain open <file>
  brain ls
  brain reindex
  brain fuzzy
  brain context <file>
  brain focus <file>
  brain think <query>
EOF
}

# ----------------------------------------------------------
# Command Loader
# ----------------------------------------------------------

load_command() {
    local file="$1"
    safe_source "$COMMANDS_DIR/$file"
}

# ----------------------------------------------------------
# Dispatcher
# ----------------------------------------------------------

brain_dispatch() {

    local cmd="${1:-help}"
    [[ $# -gt 0 ]] && shift

    case "$cmd" in

        # ---- System ----
        status)
            load_command "status.sh"
            cmd_status "$@"
            ;;

        doctor)
            load_command "doctor.sh"
            cmd_doctor "$@"
            ;;

        # ---- Memory ----
        new)
            preflight_check
            load_command "new.sh"
            cmd_new "$@"
            ;;

        search)
            preflight_check
            safe_source "$MEMORY_QUERY"
            load_command "search.sh"
            cmd_search "$@"
            ;;

        open)
            preflight_check
            load_command "open.sh"
            cmd_open "$@"
            ;;

        ls)
            preflight_check
            load_command "ls.sh"
            cmd_ls "$@"
            ;;

        reindex)
            preflight_check
            safe_source "$MEMORY_INDEX"
            load_command "reindex.sh"
            cmd_reindex "$@"
            ;;

        fuzzy)
            preflight_check
            load_command "fuzzy.sh"
            cmd_fuzzy "$@"
            ;;

        # ---- Context Layer ----
        context)
            preflight_check
            load_command "context.sh"
            cmd_context "$@"
            ;;

        focus)
            preflight_check
            load_command "context.sh"
            cmd_focus "$@"
            ;;

        # ---- Cognitive Layer ----
        think)
            preflight_check
            load_command "think.sh"
            cmd_think "$@"
            ;;

        help|--help|-h)
            usage
            ;;

        *)
            log_error "Unknown command: $cmd"
            echo
            usage
            exit 1
            ;;
    esac
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Environment Configuration
# ----------------------------------------------------------
# - Idempotent
# - Portable (auto-detect root)
# - Safe overrides
# - Readonly guarantees
# - Future multi-brain ready
# ==========================================================

# Prevent double loading
[[ -n "${BRAIN_ENV_LOADED:-}" ]] && return 0
readonly BRAIN_ENV_LOADED=1

# ----------------------------------------------------------
# Detect KaoBox root (portable install)
# ----------------------------------------------------------

if [[ -z "${KAOBOX_ROOT:-}" ]]; then
    KAOBOX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
fi

readonly KAOBOX_ROOT
export KAOBOX_ROOT

# ----------------------------------------------------------
# Base paths (allow override BEFORE sourcing)
# ----------------------------------------------------------

: "${BRAIN_ROOT:=/data/brain}"

# Modules live relative to installation
: "${MODULES_ROOT:=$KAOBOX_ROOT/modules}"

readonly BRAIN_ROOT
readonly MODULES_ROOT

# ----------------------------------------------------------
# Derived paths
# ----------------------------------------------------------

: "${NOTES_DIR:=$BRAIN_ROOT/notes}"
: "${INDEX_DIR:=$BRAIN_ROOT/.index}"
: "${BRAIN_DB:=$INDEX_DIR/brain.db}"
: "${LOG_DIR:=$KAOBOX_ROOT/logs}"

# Memory Engine entrypoint
: "${INDEX_SCRIPT:=$MODULES_ROOT/memory/index.sh}"

readonly NOTES_DIR
readonly INDEX_DIR
readonly BRAIN_DB
readonly LOG_DIR
readonly INDEX_SCRIPT

# ----------------------------------------------------------
# Ensure critical directories exist
# ----------------------------------------------------------

mkdir -p "$BRAIN_ROOT" "$INDEX_DIR" "$LOG_DIR" 2>/dev/null

# ----------------------------------------------------------
# Export environment
# ----------------------------------------------------------

export BRAIN_ROOT
export MODULES_ROOT
export NOTES_DIR
export INDEX_DIR
export BRAIN_DB
export LOG_DIR
export INDEX_SCRIPT
#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox Brain - Lock System
# ----------------------------------------------------------
# - Deterministic
# - Idempotent
# - Dynamic FD allocation
# - Safe release
# ==========================================================

[[ -n "${BRAIN_LOCK_LOADED:-}" ]] && return 0
readonly BRAIN_LOCK_LOADED=1

: "${LOCK_DIR:=$INDEX_DIR/.lock}"
: "${LOCK_FILE:=$LOCK_DIR/brain.lock}"

readonly LOCK_DIR
readonly LOCK_FILE

# Dynamic FD (assigned at runtime)
BRAIN_LOCK_FD=""

acquire_lock() {

    # Prevent double acquisition in same process
    if [[ -n "${BRAIN_LOCK_FD:-}" ]]; then
        echo "[Brain] Lock already acquired in this process."
        return 1
    fi

    mkdir -p "$LOCK_DIR"

    exec {BRAIN_LOCK_FD}>"$LOCK_FILE"

    if ! flock -n "$BRAIN_LOCK_FD"; then
        exec {BRAIN_LOCK_FD}>&-
        BRAIN_LOCK_FD=""
        echo "[Brain] Another process is running. Aborting."
        return 1
    fi
}

release_lock() {

    if [[ -z "${BRAIN_LOCK_FD:-}" ]]; then
        return 0
    fi

    flock -u "$BRAIN_LOCK_FD" 2>/dev/null || true
    exec {BRAIN_LOCK_FD}>&- 2>/dev/null || true

    BRAIN_LOCK_FD=""
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Preflight Checks
# ----------------------------------------------------------
# - Idempotent
# - Non-destructive
# - Validates DB integrity
# ==========================================================

[[ -n "${BRAIN_PREFLIGHT_LOADED:-}" ]] && return 0
readonly BRAIN_PREFLIGHT_LOADED=1

preflight_check() {

    # 1️⃣ Environment sanity
    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[FATAL] BRAIN_DB not defined"
        return 1
    }

    [[ -n "${INDEX_DIR:-}" ]] || {
        echo "[FATAL] INDEX_DIR not defined"
        return 1
    }

    # 2️⃣ Directory existence
    [[ -d "$INDEX_DIR" ]] || {
        echo "[FATAL] Index directory not found: $INDEX_DIR"
        return 1
    }

    # 3️⃣ Database existence
    [[ -f "$BRAIN_DB" ]] || {
        echo "[FATAL] Brain database not found at $BRAIN_DB"
        return 1
    }

    # 4️⃣ SQLite integrity check
    if ! sqlite3 "$BRAIN_DB" "PRAGMA integrity_check;" | grep -q "ok"; then
        echo "[FATAL] Brain database integrity check failed"
        return 1
    fi

    return 0
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Output Renderer
# ----------------------------------------------------------
# - Idempotent
# - CLI Table mode
# - JSON mode
# - Unified formatting layer
# ==========================================================

[[ -n "${BRAIN_RENDERER_LOADED:-}" ]] && return 0
readonly BRAIN_RENDERER_LOADED=1

RENDER_MODE="${RENDER_MODE:-table}"   # table | json | raw

# ----------------------------------------------------------
# Internal: escape JSON
# ----------------------------------------------------------

_json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# ----------------------------------------------------------
# Render Table
# ----------------------------------------------------------

_render_table() {

    local rows=("$@")

    [[ ${#rows[@]} -eq 0 ]] && {
        echo "No results."
        return 0
    }

    printf "%-6s %-30s %s\n" "ID" "TITLE" "PATH"
    printf "%-6s %-30s %s\n" "----" "------------------------------" "---------------------------"

    for row in "${rows[@]}"; do
        IFS=$'\t' read -r id path title score <<< "$row"
        printf "%-6s %-30s %s\n" "$id" "${title:0:28}" "$path"
    done
}

# ----------------------------------------------------------
# Render JSON
# ----------------------------------------------------------

_render_json() {

    local rows=("$@")

    printf "[\n"
    local first=1

    for row in "${rows[@]}"; do
        IFS=$'\t' read -r id path title score <<< "$row"

        [[ $first -eq 0 ]] && printf ",\n"
        first=0

        printf "  {\n"
        printf "    \"id\": \"%s\",\n" "$(_json_escape "$id")"
        printf "    \"path\": \"%s\",\n" "$(_json_escape "$path")"
        printf "    \"title\": \"%s\",\n" "$(_json_escape "$title")"
        printf "    \"score\": \"%s\"\n" "$(_json_escape "${score:-}")"
        printf "  }"
    done

    printf "\n]\n"
}

# ----------------------------------------------------------
# Public API
# ----------------------------------------------------------

render_results() {

    local mode="${1:-$RENDER_MODE}"
    shift || true

    local rows=("$@")

    case "$mode" in
        table)
            _render_table "${rows[@]}"
            ;;
        json)
            _render_json "${rows[@]}"
            ;;
        raw)
            printf "%s\n" "${rows[@]}"
            ;;
        *)
            echo "[Renderer] Unknown mode: $mode"
            return 1
            ;;
    esac
}
#!/usr/bin/env bash

# ==========================================================
# KaoBox Brain - Input Sanitization
# ----------------------------------------------------------
# - Idempotent
# - Safe for SQL
# - Preserves FTS operators
# ==========================================================

[[ -n "${BRAIN_SANITIZE_LOADED:-}" ]] && return 0
readonly BRAIN_SANITIZE_LOADED=1

sanitize_sql() {
    # Escape single quotes for SQLite
    local input="$1"
    printf "%s" "$input" | sed "s/'/''/g"
}

sanitize_fts() {
    local input="$1"

    # Remove only dangerous SQL control characters
    # Preserve: letters, numbers, space, _, -, *, :, ", parentheses
    printf "%s" "$input" \
        | tr -cd '[:alnum:] _-*:"()'
}
# KaoBox Agent Specification

## Purpose

The KaoBox Agent is a structured operational intelligence layer
running on top of the deterministic core.

It does not replace the system.
It orchestrates it.

---

## Agent Nature

The agent is:

- Deterministic-aware
- State-conscious
- Modular
- Tool-driven
- Language-aware

It must never:
- Corrupt core
- Modify base manifests directly
- Break deterministic guarantees

---

## Agent Layers

### 1. Perception

Reads:
- state/
- manifests
- module availability
- environment variables

### 2. Reasoning

Uses:
- defined tools
- deterministic scripts
- explicit logic flows

No hidden state allowed.

### 3. Action

Allowed actions:
- Execute modules
- Update runtime state
- Log operations
- Trigger safe hooks

Forbidden:
- Direct modification of core/
- Direct modification of base/

---

## Memory

Memory is modular.

Current module:
    modules/memory

Memory must:
- Be indexed
- Be explicit
- Be recoverable

---

## Safety Model

The agent operates under:

- Explicit boundaries
- Observable actions
- Logged operations

All state mutation must be traceable.

---

## Evolution

Future agent upgrades must:

- Preserve core determinism
- Remain modular
- Be documented in roadmap
# KaoBox Architecture

## Overview

KaoBox is a modular cognitive infrastructure designed as a deterministic brain kernel.

Root path:

/opt/kaobox

The system is layered to enforce:

- Determinism
- Isolation
- Explicit state
- Controlled extensibility

---

# System Layers

---

## Layer 0 — Operating System

Environment:
- Linux
- Bash
- SQLite

KaoBox assumes a controlled POSIX runtime.

---

## Layer 1 — Core (Deterministic Kernel)

Directory:
core/
init.sh
state/
lang/

Responsibilities:

- Environment bootstrap
- Logging system
- Sanity validation
- Localization
- Locking
- Deterministic execution

Core must:

- Not depend on modules
- Not contain business logic
- Remain minimal and stable

Core = infrastructure only.

---

## Layer 2 — Cognitive Layer (lib/brain/)

    - context/
    - think/

Directory:
modules/

Modules contain domain engines.

Current module:
modules/memory/

### Memory Module Structure

memory/
├── engine/      → low-level indexing logic
├── context/     → adaptive contextual ranking engine
├── index.sh
├── query.sh
├── gc.sh
└── init.sh

Modules must:

- Be isolated
- Not mutate core
- Expose explicit interfaces
- Remain composable

---

## Context Engine (Phase 3.2)

Location:
modules/memory/context/

Components:

- resolver.sh → Collect contextual layers
- scorer.sh   → Adaptive weighted ranking
- session.sh  → Active node persistence

## Think Engine (Phase 3.2+)

Location:
lib/brain/context/

Components:

- engine.sh  → orchestration
- ranker.sh  → composite scoring

### Think Model

FTS relevance (memory/query.sh)
+ Session focus boost
= Composite ranking

Future:
+ Graph proximity boost
+ Tag similarity
+ Temporal blending

### Context Layers

- SELF
- GRAPH_OUT
- GRAPH_IN
- RECENT

### Ranking Model

Score =
    (Layer Weight × Temporal Decay)
    + Session Boost

Layer Weights:

- SELF      → 4
- GRAPH_OUT → 3
- GRAPH_IN  → 2
- RECENT    → 1

Temporal Decay:

- 0–1 days   → 100%
- 2–7 days   → 70%
- 8–30 days  → 40%
- >30 days   → 20%

Session Boost:

- +5 if note is active focus

This creates an adaptive contextual graph.

---

## Layer 3 — CLI Interface

## Think Engine

Location:
lib/brain/think/

Purpose:
Composite retrieval and ranking layer.

Dependencies:
- memory/query.sh
- context/session.sh

Scoring:
normalized_fts + focus_boost

---

## Layer 4 — Runtime State

Directory:
state/

Contains:

- version state
- language state
- runtime flags

Mutable by design.

---

## Layer 5 — Documentation

Directory:
doc/

Contains:

- Architecture definitions
- Agent specifications
- Roadmap
- Phase history
- Test protocols

Documentation is considered part of the system contract.

---

# Design Principles

1. Deterministic Core  
2. Modular Engines  
3. Explicit State  
4. Minimal Coupling  
5. Infrastructure First  
6. Intelligence as Layered Emergence  

---

# Architectural Identity

KaoBox is not a workspace.

It is a programmable cognitive kernel.

Where most systems optimize UI,
KaoBox optimizes structured cognition.

---

# Future Extensions

- Hybrid semantic ranking (FTS integration)
- Usage reinforcement learning
- Multi-module orchestration
- Agentic execution layer

# Think Pipeline

User Query
   ↓
FTS Query (modules/memory/query.sh)
   ↓
Think Engine (lib/brain/think/engine.sh)
   ↓
Ranker (composite scoring)
   ↓
Renderer

---

# Status

Phase 3.2 — Context Engine: STABLE
# KaoBox Module Contract

## Purpose

This document defines how modules interact with the KaoBox Core.

Modules extend the system.
They must never modify or weaken the Core.

The Core remains deterministic.
Modules provide business logic.

---

# Architectural Principle

Core = Infrastructure  
Modules = Engines  

Separation is mandatory.

---

# Location

All modules must reside in:

/opt/kaobox/modules/<module_name>/

Example:
/opt/kaobox/modules/memory/

---

# Required Structure

Each module must contain:

- init.sh        → initialization entrypoint
- index.sh       → public module entry
- query.sh       → exposed query interface (if applicable)

Recommended structure:

module/
├── engine/      → low-level logic
├── context/     → adaptive logic (if applicable)
├── init.sh
├── index.sh
├── query.sh
└── gc.sh

Modules must explicitly expose their public interface.

---

# Core Responsibilities

Core is responsible for:

- Environment bootstrap
- Logging system
- Sanity validation
- Locking
- Localization
- Runtime state management

Core provides:

- Logging utilities
- Environment variables
- Controlled execution context
- Stable runtime state

Core must remain:

- Deterministic
- Minimal
- Module-agnostic

---

# Allowed Interactions

Modules MAY:

- Use Core logging utilities
- Read from state/
- Write to logs/
- Use defined environment variables
- Persist their own data
- Register CLI commands through the dispatcher layer
- Maintain their own internal SQLite schema

Modules MAY implement:

- Adaptive ranking
- Context engines
- Graph logic
- Business-specific storage

---

# Forbidden Interactions

Modules must NOT:

- Modify core/
- Modify base/
- Override bin/brain
- Directly alter golden.version
- Modify other modules
- Depend on undocumented global variables

Core integrity is non-negotiable.

---

# CLI Separation Rule

CLI layer (lib/brain/commands/) must:

- Validate arguments
- Call module interfaces
- Not contain business logic

Modules must expose callable functions.
CLI must orchestrate, not compute.

---

# Isolation Rule

Modules must:

- Be self-contained
- Fail safely
- Handle their own schema
- Not assume external state unless explicitly provided

If a module crashes,
Core must remain operational.

---

# Determinism Rule

Core is deterministic.

Modules may introduce adaptive behavior,
but only inside their isolated engine.

Example:
- Context ranking
- Temporal decay
- Session boosting

These must never compromise Core stability.

---

# Hook System (Future Extension)

Planned standard hooks:

- on_init
- on_before_execute
- on_after_execute
- on_shutdown

Hooks must be:

- Explicitly registered
- Non-invasive
- Optional

Core must function without any module installed.

---

# Data Ownership Rule

Each module owns:

- Its database schema
- Its indexing logic
- Its ranking model
- Its internal cache

Core owns:

- Runtime state
- System versioning
- Execution safety

---

# Failure Model

Modules must:

- Fail explicitly
- Log errors
- Not silently corrupt state
- Not block system startup

Graceful degradation is mandatory.

---

# Extension Philosophy

Modules are engines.

They may introduce:

- Intelligence
- Context
- Learning
- Ranking

But never structural instability.

---

# Contract Summary

Core:
- Deterministic
- Stable
- Minimal

Modules:
- Isolated
- Explicit
- Replaceable
- Evolvable

KaoBox grows through modules,
not by expanding the Core.
# KaoBox Roadmap

Version: v2.9  
Last Update: 2026-03-04

---

# Vision

Infrastructure before intelligence.  
Stability before expansion.  
Determinism before automation.

KaoBox is a modular deterministic system orchestrator
with a hardened cognitive memory engine (Brain)
and an emerging structured agent layer.

---

# Phase 1 — Structural Foundation ✅

Objectives:

- Clean layered architecture
- Deterministic Core
- Strict separation between Core and Modules
- Environment contract stabilization
- Modular engine design
- Documentation baseline

Memory:

- Brain module initialized
- SQL-only emission model
- Transaction wrapper architecture
- Explicit schema ownership

Status: COMPLETE

---

# Phase 2 — Production Hardening (Brain v2.8) ✅

Objective:

Transform Brain into a production-grade,
concurrency-safe memory engine.

Delivered:

## SQLite Hardening

- WAL mode enabled
- FULL synchronous durability
- BEGIN IMMEDIATE transactional control
- Runtime `.timeout` injection

## Safety Layer

- Integrity check integrated into `brain doctor`
- Schema validation
- Strict environment validation

## Maintenance Automation

- Intelligent WAL checkpoint (batch only)
- Automatic `PRAGMA optimize` post-batch
- Transactional garbage collector

## Guarantees

- Crash-safe writes
- Multi-process safe indexing
- Controlled WAL growth
- Zero output regression

Tag: v2.8  
Branch: release/brain-v2.8  
Status: STABLE

---

# Phase 3 — Operational Intelligence (v2.9) 🚧

Objective:

Build a stable operational layer
on top of the hardened infrastructure.

## Phase 3.1 — CLI Stabilization

- Command normalization
- Dispatcher cleanup
- Argument validation consistency
- Shell integration
- Completion system

## Phase 3.2 — Context Engine ✅

Location:
modules/memory/context/

Delivered:

- Context resolver
- Adaptive scoring model
- Session focus tracking
- Layered ranking system

Context Layers:

- SELF
- GRAPH_OUT
- GRAPH_IN
- RECENT

Scoring Model:

Score =
    (Layer Weight × Temporal Decay)
    + Session Boost

Outcome:

Context-aware memory navigation
without breaking Core determinism.

Status: STABLE

---

## Phase 3.3 — Observability & Health (Next)

Goals:

- Runtime health scoring
- Context diagnostics
- Brain explainability output
- Focus traceability
- CLI introspection tools

Expected outcome:

Transparent operational intelligence layer.

Status: IN PROGRESS

---

# Phase 4 — Adaptive Layer

Goal:

Introduce controlled adaptive intelligence
above deterministic infrastructure.

Planned:

- Hybrid semantic indexing (FTS + graph)
- Context-aware execution policies
- Cross-note graph reinforcement
- Multi-module orchestration
- Structured planning layer
- Agent task routing

Constraint:

Adaptive logic must remain modular.
Core must remain deterministic.

Expected outcome:

Semi-autonomous structured agent.

Status: PLANNED

---

# Phase 5 — Distributed Brain (Long-Term)

Vision:

Extend KaoBox beyond a single runtime.

Goals:

- Multi-brain instances
- State replication
- Remote orchestration
- Snapshot & recovery layer
- External toolchain integration

Expected outcome:

Distributed agentic infrastructure.

Status: VISION

---

# Core Design Principles

- SQL-only engine emission
- Deterministic transaction boundaries
- No hidden state
- Modular isolation
- Crash-safe by design
- Explicit state mutation
- Versioned architectural milestones

---

# Current State Summary

Brain v2.8 is production-hardened and concurrency-safe.

Phase 3.2 Context Engine is operational and stable.

KaoBox is transitioning from:

Infrastructure maturity  
→ Operational intelligence  
→ Structured adaptive cognition
# KaoBox TODO

Version: v2.9  
Aligned with Phase 3.2 completion

---

# Immediate (Phase 3.3 — Observability)

- [ ] Implement context explainability output (`brain context --explain`)
- [ ] Add health scoring command (`brain health`)
- [ ] Add session inspection command (`brain session`)
- [ ] Add runtime diagnostics summary
- [ ] Validate CLI exit codes consistency
- [ ] Harden pipefail across dispatcher

---

# Short Term (Stabilization Layer)

- [ ] Structured logging format (JSON-compatible)
- [ ] Add state validation script (`brain validate`)
- [ ] Improve memory indexing performance benchmarks
- [ ] Add module enable/disable mechanism
- [ ] Add module capability introspection

---

# Mid Term (Phase 4 Preparation)

- [ ] Hybrid semantic indexing (FTS + graph ranking)
- [ ] Context reinforcement signals
- [ ] Execution policy framework
- [ ] Multi-module orchestration model
- [ ] Agent task routing prototype

---

# Long Term (Distributed Brain)

- [ ] Snapshot export/import mechanism
- [ ] Remote node synchronization
- [ ] Multi-instance coordination
- [ ] External toolchain connectors
- [ ] Replication strategy design

---

# Architectural Constraint Reminder

All future work must:

- Preserve Core determinism
- Maintain module isolation
- Avoid hidden state
- Remain reversible where possible

---

# Next: Graph Boost

- Boost notes linked to active note
- Weight configurable
- Based on links table
# KaoBox Phase History

This document tracks architectural milestones.
Each phase represents a structural evolution of the system.

---

# Phase 1 — Structural Foundation ✅

Version: v1.0.0-alpha  
Status: COMPLETED

## Scope

- Clean layered architecture
- Deterministic Core separation
- Module isolation
- Documentation baseline
- Roadmap formalization

## Key Decisions

- /opt/kaobox as single source of truth
- Core cannot be modified by modules
- Explicit runtime state directory
- Infrastructure before intelligence
- Modules extend, never mutate

## Exit Criteria (Met)

- Core validated
- CLI structure defined
- Module contract formalized
- Deterministic boundaries enforced

---

# Phase 2 — Production Hardening (Brain v2.8) ✅

Version: v2.8  
Status: COMPLETED  
Branch: release/brain-v2.8

## Scope

Transform Brain into a concurrency-safe,
production-grade memory engine.

## Delivered

### SQLite Hardening

- WAL mode
- FULL synchronous durability
- BEGIN IMMEDIATE transactional model
- Runtime timeout injection

### Safety & Integrity

- Integrated integrity checks
- Schema validation
- Strict environment validation
- Transaction wrapper architecture

### Maintenance Automation

- Controlled WAL checkpointing
- Automatic PRAGMA optimize
- Transactional garbage collector

## Guarantees Achieved

- Crash-safe writes
- Multi-process safe indexing
- Controlled WAL growth
- Zero output regression

Phase 2 marks the stabilization of the infrastructure layer.

---

# Phase 3 — Operational Intelligence 🚧

Version: v2.9  
Status: IN PROGRESS

Goal:

Build structured operational intelligence
on top of hardened infrastructure.

---

## Phase 3.1 — CLI Stabilization ✅

- Command normalization
- Dispatcher cleanup
- Separation between CLI and business logic
- Shell integration
- Completion groundwork

CLI now orchestrates modules without containing logic.

---

## Phase 3.2 — Context Engine ✅

Location:
modules/memory/context/

## Phase 3.2+ — Think Engine Stabilization

- Composite ranking stabilized
- Safe TAB parsing
- Session-based focus boost integrated
- Strict dependency loading enforced
- Documentation aligned with structure

### Delivered

- Context resolver
- Layered context model (SELF, GRAPH_IN, GRAPH_OUT, RECENT)
- Adaptive scoring engine
- Temporal decay model
- Session focus persistence

### Architectural Impact

- Introduced contextual awareness
- Preserved Core determinism
- Maintained module isolation

This phase marks the first controlled adaptive layer.

---

## Phase 3.3 — Observability (Next)

Planned:

- Health scoring system
- Context explainability output
- Focus trace tracing
- Runtime introspection commands

Objective:

Make intelligence transparent and inspectable.

---

# Phase 4 — Adaptive Layer (Planned)

Goal:

Extend contextual intelligence toward structured agent behavior.

Planned capabilities:

- Hybrid semantic indexing (FTS + graph)
- Cross-note reinforcement signals
- Multi-module orchestration
- Structured task planning
- Controlled execution graphs

Constraint:

Core must remain deterministic.
Adaptation must remain modular.

---

# Phase 5 — Distributed Brain (Vision)

Long-term evolution:

- Multi-instance coordination
- State replication
- Remote orchestration
- Snapshot & recovery model
- External toolchain integration

## Phase 6 – Think Engine Stabilization

Date: 2026-03-05

- Fixed parsing robustness in ranker
- Integrated session-based focus boost
- Enforced strict dependency loading
- Stabilized composite scoring

---

# Architectural Trajectory

Phase 1 → Deterministic Foundation  
Phase 2 → Infrastructure Hardening  
Phase 3 → Contextual Intelligence  
Phase 4 → Structured Adaptation  
Phase 5 → Distributed Cognition  

---

# Current Position

Infrastructure: Stable  
Memory Engine: Production-grade  
Context Engine: Operational  
Agent Layer: Emerging  

KaoBox has transitioned from a structural system
to a controlled cognitive infrastructure.
# KaoBox Test Protocol

Version: v2.9  
Aligned with Phase 3.2 completion

A version can be validated only if all checks pass.

Validation must confirm:

- Determinism
- Isolation
- Integrity
- Reproducibility

---

# 1️⃣ Core Validation

Core must remain deterministic and stable.

Checks:

- env.sh loads without error
- sanity.sh returns success
- logger.sh initializes properly
- shell bootstrap executes without side effects
- No module directly modifies core/

Failure of any check invalidates the release.

---

# 2️⃣ SQLite & Memory Engine Validation (Phase 2)

Checks:

- WAL mode enabled
- PRAGMA synchronous = FULL
- Integrity check passes (`brain doctor`)
- Transaction wrapper enforces BEGIN IMMEDIATE
- No partial writes after simulated crash
- Reindex is idempotent
- No schema drift detected

Memory must be:

- Deterministic to rebuild
- Crash-safe
- Concurrency-safe

---

# 3️⃣ Context Engine Validation (Phase 3.2)

Checks:

- resolve_context returns structured layers
- score_context returns sorted numeric scores
- SELF note appears in results
- Session boost applied correctly
- Temporal decay behaves consistently
- No direct SQL inside CLI commands

Scoring must be reproducible.

Context must not mutate state unexpectedly.

---

# 4️⃣ CLI Validation

Checks:

- brain --help executes
- brain exits cleanly
- Commands return proper exit codes
- No uncaught errors
- Dispatcher does not contain business logic
- set -o pipefail behavior validated

CLI must orchestrate, not compute.

---

# 5️⃣ Module Validation

Checks:

- Modules load without breaking Core
- memory module initializes safely
- No module overrides bin/brain
- No module modifies base/
- Modules handle failure gracefully

Isolation is mandatory.

---

# 6️⃣ State Validation

Checks:

- golden.version matches runtime
- state directory writable
- No forbidden file mutation
- Session focus persistence works
- Runtime flags consistent

State must be explicit and recoverable.

---

# 7️⃣ Determinism Validation

Checks:

- Reindex twice → identical DB state
- Context query twice → identical ordering (if no new writes)
- No hidden runtime memory
- No implicit global mutation

Core must remain deterministic.
Adaptive behavior must remain bounded to modules.

---

# 8️⃣ Validation Result

All checks must pass before:

- Phase closure
- Version bump
- Release tagging
- Documentation freeze

Failure to meet any check blocks release.
# KaoBox

KaoBox est une infrastructure agentique modulaire conçue pour construire un noyau cognitif local, déterministe et extensible.

Il fournit une base architecturale stable pour développer :

- des systèmes de mémoire structurée
- des moteurs transactionnels
- des agents connectés à une connaissance persistante

---

## ✨ Principes

KaoBox repose sur des fondations strictes :

- **Modularité** — chaque composant est isolé et remplaçable  
- **Déterminisme** — comportement prévisible et traçable  
- **Transactionnalité** — cohérence garantie  
- **Local-first** — aucune dépendance cloud  
- **Portabilité** — Linux-first, reproductible  
- **Architecture avant interface**

KaoBox n’est pas orienté UI-first.  
Il est conçu comme un **kernel cognitif programmable**.

---

## 🧠 Vision

Construire une infrastructure capable de :

- Structurer de la connaissance en Markdown
- Maintenir un index transactionnel robuste
- Générer un graphe cohérent (liens entrants / sortants)
- Prioriser le contexte via un moteur adaptatif
- Alimenter des agents structurés
- Servir de mémoire persistante programmable

---

## 🗂 Structure du projet

bin/               → CLI utilisateur
core/              → noyau déterministe (env, logger, sanity, shell)
lib/brain          → dispatcher & commandes CLI
lib/brain/context/   ""
lib/brain/think/     "" 
modules/memory/    → moteur mémoire transactionnel 
profiles/          → isolation multi-instance
state/             → état runtime  
logs/              → journaux  
doc/               → documentation officielle  
tests/             → validation n

---

## 🏗 Architecture

Séparation stricte des couches :

CLI (bin/)
↓
Dispatcher (lib/brain/dispatcher.sh)
↓
Commands (lib/brain/commands/)
↓
Cognitive Layer (lib/brain/context + think)
↓
Memory Module (modules/memory/)
↓
SQLite + Filesystem

### Règles fondamentales

- Le CLI ne parle jamais directement à la base de données.
- Les modules sont auto-contenus.
- Le noyau (`core/`) ne dépend d’aucun module.
- Les transactions sont centralisées.
- L’état système est explicitement versionné.
- Le déterminisme du Core est non négociable.

---

## 📦 Module Memory (Brain Engine)

### Engine Layer

- FTS5
- WAL
- Transaction control
- Link graph
- Tag system
- Hash + mtime tracking

### Context Layer (Phase 3.2)

- Layered context resolution
- Temporal decay
- Session focus boost

## 🧠 Think Engine (Context-Aware Retrieval)

The Think Engine combines:
Composite ranking:
composite_score = normalized_fts + focus_boost
Focus Boost: +5 on active note

---

## 🚀 Installation (dev)

```bash
git clone <repo>
cd kaobox
./init.sh

---
🧪 Tests
./tests/test_memory_index.sh

---
🛣 Roadmap

Voir :
doc/roadmap/ROADMAP.md
doc/state/PHASE_HISTORY.md

---
📌 Objectif long terme

KaoBox vise à devenir :
Une base stable pour des systèmes cognitifs locaux
Un socle pour agents structurés
Une infrastructure Brain portable et extensible
Un noyau déterministe sur lequel greffer de l’intelligence contrôlée

---
📜 Version

Track: v2.9
Phase: 3.2 — Context Engine Stable
Think Engine: v1 Stable
Status: Operational Intelligence Base
