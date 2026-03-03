#!/usr/bin/env bash
set -euo pipefail

[[ -n "${BRAIN_DB:-}" ]] || {
    echo "[Memory] BRAIN_DB not defined"
    return 1
}

# --------------------------------------------------
# Utils
# --------------------------------------------------

_check_absolute_path() {
    local path="$1"
    [[ "$path" == /* ]] || {
        echo "[ERROR] Absolute path required: $path"
        return 1
    }
}

_sql_escape() {
    printf "%s" "$1" | sed "s/'/''/g"
}

_get_file_metadata() {
    local file="$1"

    local hash
    hash=$(sha256sum "$file" | awk '{print $1}')

    local mtime
    mtime=$(stat -c %Y "$file")

    local size
    size=$(stat -c %s "$file")

    echo "$hash|$mtime|$size"
}

_should_reindex() {
    local file="$1"

    local safe_file
    safe_file="$(_sql_escape "$file")"

    local row
    row=$(sqlite3 "$BRAIN_DB" \
        "SELECT content_hash, file_mtime, file_size FROM notes WHERE path='$safe_file';" \
        || true)

    [[ -z "$row" ]] && return 0

    local new_meta
    new_meta=$(_get_file_metadata "$file")

    local new_hash new_mtime new_size
    IFS="|" read -r new_hash new_mtime new_size <<< "$new_meta"

    local old_hash old_mtime old_size
    IFS="|" read -r old_hash old_mtime old_size <<< "$row"

    if [[ "$new_hash" == "$old_hash" &&
          "$new_mtime" == "$old_mtime" &&
          "$new_size" == "$old_size" ]]; then
        return 1
    fi

    return 0
}

# --------------------------------------------------
# SQL Builder (notes + FTS + tags)
# --------------------------------------------------

_build_index_sql() {
    local file="$1"

    local meta
    meta=$(_get_file_metadata "$file")

    local hash mtime size
    IFS="|" read -r hash mtime size <<< "$meta"

    local title
    title="$(_sql_escape "$(basename "$file")")"

    local safe_file
    safe_file="$(_sql_escape "$file")"

    local safe_hash
    safe_hash="$(_sql_escape "$hash")"

    local content
    content="$(_sql_escape "$(cat "$file")")"

    local tags
    tags=$(grep -i '^Tags:' "$file" 2>/dev/null \
        | sed 's/^Tags:[[:space:]]*//' \
        | grep -o '#[a-zA-Z0-9_-]\+' \
        | sed 's/#//' \
        | sort -u || true)

cat <<SQL
INSERT INTO notes (title, path, updated_at, content_hash, file_mtime, file_size)
VALUES ('$title', '$safe_file', datetime('now'),
        '$safe_hash', $mtime, $size)
ON CONFLICT(path) DO UPDATE SET
  title=excluded.title,
  updated_at=datetime('now'),
  content_hash=excluded.content_hash,
  file_mtime=excluded.file_mtime,
  file_size=excluded.file_size;

DELETE FROM note_tags
WHERE note_id = (SELECT id FROM notes WHERE path='$safe_file');

DELETE FROM notes_fts
WHERE rowid = (SELECT id FROM notes WHERE path='$safe_file');

INSERT INTO notes_fts (rowid, title, content)
SELECT id, '$title', '$content'
FROM notes
WHERE path='$safe_file';
SQL

    for tag in $tags; do
        local safe_tag
        safe_tag="$(_sql_escape "$tag")"

cat <<SQL
INSERT INTO tags(name)
VALUES ('$safe_tag')
ON CONFLICT(name) DO NOTHING;

INSERT INTO note_tags(note_id, tag_id)
SELECT n.id, t.id
FROM notes n, tags t
WHERE n.path='$safe_file' AND t.name='$safe_tag'
ON CONFLICT(note_id, tag_id) DO NOTHING;
SQL
    done
}

# --------------------------------------------------
# Public API
# --------------------------------------------------

index_note() {
    local file="$1"

    _check_absolute_path "$file" || return 1
    [[ -f "$file" ]] || {
        echo "[ERROR] File not found: $file"
        return 1
    }

    if ! _should_reindex "$file"; then
        log INFO "Skipped (unchanged): $file"
        return 0
    fi

    sqlite3 "$BRAIN_DB" <<EOF
PRAGMA foreign_keys=ON;
PRAGMA busy_timeout=5000;
BEGIN IMMEDIATE;
$(_build_index_sql "$file")
COMMIT;
EOF

    log INFO "Indexed: $file"
}

garbage_collect() {
    sqlite3 "$BRAIN_DB" "SELECT path FROM notes;" | while read -r path; do
        if [[ ! -f "$path" ]]; then
            local safe_path
            safe_path="$(_sql_escape "$path")"

            sqlite3 "$BRAIN_DB" <<EOF
BEGIN IMMEDIATE;
DELETE FROM note_tags
WHERE note_id = (SELECT id FROM notes WHERE path='$safe_path');
DELETE FROM notes_fts
WHERE rowid = (SELECT id FROM notes WHERE path='$safe_path');
DELETE FROM notes
WHERE path='$safe_path';
COMMIT;
EOF
            log INFO "Removed missing file: $path"
        fi
    done
}

reindex_all() {
    local files=("$@")

    [[ ${#files[@]} -eq 0 ]] && return 0

    sqlite3 "$BRAIN_DB" <<EOF
PRAGMA foreign_keys=ON;
PRAGMA busy_timeout=5000;
BEGIN IMMEDIATE;
$(for f in "${files[@]}"; do
    _build_index_sql "$f"
done)
COMMIT;
EOF

    log INFO "Batch reindex completed (${#files[@]} files)"
}
