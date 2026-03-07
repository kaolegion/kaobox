#!/usr/bin/env bash
# ==========================================================
# KAOBOX - File Analysis Helper (v3 Hardened)
# ----------------------------------------------------------
# Shared analysis state for memory indexing pipeline
# Produces:
#   FILE_TITLE
#   FILE_HASH
#   FILE_MTIME
#   FILE_SIZE
#   FILE_CONTENT
# ==========================================================

analyze_file() {
    local file="$1"

    require_file "$file" || return 1

    unset FILE_TITLE FILE_HASH FILE_MTIME FILE_SIZE FILE_CONTENT

    # Shared globals populated here and consumed by:
    #   metadata_sql / fts_sql / tags_sql / links_sql
    # shellcheck disable=SC2034
    FILE_TITLE="$(extract_title "$file")" || return 1
    # shellcheck disable=SC2034
    FILE_HASH="$(compute_hash "$file")" || return 1
    # shellcheck disable=SC2034
    FILE_MTIME="$(file_mtime "$file")" || return 1
    # shellcheck disable=SC2034
    FILE_SIZE="$(file_size "$file")" || return 1
    # shellcheck disable=SC2034
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
    local file="$1"
    grep -m1 '^# ' "$file" | sed 's/^# //'
}

compute_hash() {
    local file="$1"
    sha256sum "$file" | awk '{print $1}'
}

file_mtime() {
    local file="$1"
    stat -c %Y "$file"
}

file_size() {
    local file="$1"
    stat -c %s "$file"
}

# ==========================================================
# SQL escape
# ==========================================================

sql_escape() {
    local value="$1"
    printf "%s" "$value" | sed "s/'/''/g"
}
