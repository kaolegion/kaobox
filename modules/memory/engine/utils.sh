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
