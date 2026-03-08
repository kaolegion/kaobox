#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KaoBox - Memory Query Engine (Hardened V2)
# ----------------------------------------------------------
# - Idempotent
# - No exit
# - Safe LIMIT
# - Consistent output
# - Graph query API
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
    local value="${1:-}"

    [[ "$value" =~ ^[0-9]+$ ]] || value="$DEFAULT_LIMIT"
    printf "%s" "$value"
}

# ----------------------------------------------------------
# FTS Query
# ----------------------------------------------------------

query_fts() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined" >&2
        return 1
    }

    local q="${1:-}"
    local limit
    limit="$(_sanitize_limit "${2:-$DEFAULT_LIMIT}")"

    [[ -z "$q" ]] && {
        echo "[Query] Empty search query" >&2
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
        echo "[Query] BRAIN_DB not defined" >&2
        return 1
    }

    local tag="${1:-}"
    local limit
    limit="$(_sanitize_limit "${2:-50}")"

    [[ -z "$tag" ]] && {
        echo "[Query] Empty tag" >&2
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
ORDER BY n.updated_at DESC, n.path ASC
LIMIT $limit;
SQL
}

# ----------------------------------------------------------
# Backlinks Query (by exact path)
# ----------------------------------------------------------

query_backlinks() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined" >&2
        return 1
    }

    local path="${1:-}"

    [[ -z "$path" ]] && {
        echo "[Query] Missing path" >&2
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
WHERE tgt.path = @path
ORDER BY src.path ASC;
SQL
}

# ----------------------------------------------------------
# Resolve Note Reference
# ----------------------------------------------------------
# Input:
#   partial path, filename, filename without .md, or title
# Output:
#   id<TAB>path<TAB>title<TAB>updated_at
#
# Resolution priority:
#   1. exact path
#   2. exact title
#   3. exact basename(path)
#   4. exact basename(path) without .md
#   5. partial path/title match
#
# Deterministic:
#   priority asc, updated_at desc, path asc
# ----------------------------------------------------------

# ----------------------------------------------------------
# Resolve Note Reference
# ----------------------------------------------------------
# Input:
#   partial path, filename, filename without .md, or title
# Output:
#   id<TAB>path<TAB>title<TAB>updated_at
#
# Resolution priority:
#   1. exact full path
#   2. exact title
#   3. exact filename suffix      (%/<ref>)
#   4. exact filename suffix .md  (%/<ref>.md)
#   5. partial path/title match
#
# Deterministic:
#   priority asc, updated_at desc, path asc
# ----------------------------------------------------------

resolve_note_ref() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined" >&2
        return 1
    }

    local ref="${1:-}"

    [[ -n "$ref" ]] || {
        echo "[Query] Empty note reference" >&2
        return 1
    }

    _sqlite_exec <<SQL
.parameter init
.parameter set @ref "$ref"
WITH ranked AS (
    SELECT id,
           path,
           title,
           updated_at,
           CASE
               WHEN path = @ref THEN 1
               WHEN lower(title) = lower(@ref) THEN 2
               WHEN lower(path) LIKE '%/' || lower(@ref) THEN 3
               WHEN lower(path) LIKE '%/' || lower(@ref) || '.md' THEN 4
               WHEN lower(path) LIKE '%' || lower(@ref) || '%'
                 OR lower(title) LIKE '%' || lower(@ref) || '%'
               THEN 5
               ELSE 99
           END AS priority
    FROM notes
)
SELECT id,
       path,
       title,
       updated_at
FROM ranked
WHERE priority < 99
ORDER BY priority ASC, updated_at DESC, path ASC
LIMIT 1;
SQL
}

# ----------------------------------------------------------
# Outgoing Links Query
# ----------------------------------------------------------
# Input:
#   source note id
# Output:
#   id<TAB>path<TAB>title<TAB>OUT
# ----------------------------------------------------------

query_outgoing_links() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined" >&2
        return 1
    }

    local note_id="${1:-}"

    [[ "$note_id" =~ ^[0-9]+$ ]] || {
        echo "[Query] Invalid note id: $note_id" >&2
        return 1
    }

    _sqlite_exec <<SQL
.parameter init
.parameter set @id "$note_id"
SELECT n.id,
       n.path,
       n.title,
       'OUT' as direction
FROM links l
JOIN notes n ON n.id = l.target_id
WHERE l.source_id = @id
ORDER BY n.path ASC;
SQL
}

# ----------------------------------------------------------
# Backlinks by Note ID
# ----------------------------------------------------------
# Input:
#   target note id
# Output:
#   id<TAB>path<TAB>title<TAB>IN
# ----------------------------------------------------------

query_backlinks_by_note() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined" >&2
        return 1
    }

    local note_id="${1:-}"

    [[ "$note_id" =~ ^[0-9]+$ ]] || {
        echo "[Query] Invalid note id: $note_id" >&2
        return 1
    }

    _sqlite_exec <<SQL
.parameter init
.parameter set @id "$note_id"
SELECT n.id,
       n.path,
       n.title,
       'IN' as direction
FROM links l
JOIN notes n ON n.id = l.source_id
WHERE l.target_id = @id
ORDER BY n.path ASC;
SQL
}

# ----------------------------------------------------------
# Neighbors Query
# ----------------------------------------------------------
# Union:
#   - outgoing
#   - incoming
# Output:
#   id<TAB>path<TAB>title<TAB>direction
# ----------------------------------------------------------

query_neighbors() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined" >&2
        return 1
    }

    local note_id="${1:-}"

    [[ "$note_id" =~ ^[0-9]+$ ]] || {
        echo "[Query] Invalid note id: $note_id" >&2
        return 1
    }

    _sqlite_exec <<SQL
.parameter init
.parameter set @id "$note_id"
SELECT n.id,
       n.path,
       n.title,
       'OUT' as direction
FROM links l
JOIN notes n ON n.id = l.target_id
WHERE l.source_id = @id

UNION ALL

SELECT n.id,
       n.path,
       n.title,
       'IN' as direction
FROM links l
JOIN notes n ON n.id = l.source_id
WHERE l.target_id = @id

ORDER BY path ASC, direction ASC;
SQL
}

# ----------------------------------------------------------
# Graph Adjacency Query
# ----------------------------------------------------------
# Input:
#   source note id
# Output:
#   target_id<TAB>target_path<TAB>target_title
# ----------------------------------------------------------

query_adjacent_note_ids() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined" >&2
        return 1
    }

    local note_id="${1:-}"

    [[ "$note_id" =~ ^[0-9]+$ ]] || {
        echo "[Query] Invalid note id: $note_id" >&2
        return 1
    }

    _sqlite_exec <<SQL
.parameter init
.parameter set @id "$note_id"
SELECT n.id,
       n.path,
       n.title
FROM links l
JOIN notes n ON n.id = l.target_id
WHERE l.source_id = @id
ORDER BY n.path ASC;
SQL
}
