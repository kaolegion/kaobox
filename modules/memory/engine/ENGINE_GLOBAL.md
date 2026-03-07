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
