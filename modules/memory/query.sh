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
#   1. exact full path
#   2. exact title
#   3. exact filename suffix      (%/<ref>)
#   4. exact filename suffix .md  (%/<ref>.md)
#   5. partial path/title match
#
# Deterministic:
#   priority asc, updated_at desc, path asc
#
# Ambiguity policy:
#   - no candidate              -> error
#   - single best candidate     -> resolved
#   - multiple best candidates  -> error
# ----------------------------------------------------------

_resolve_note_ref_candidates() {

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
       updated_at,
       priority
FROM ranked
WHERE priority < 99
ORDER BY priority ASC, updated_at DESC, path ASC;
SQL
}

resolve_note_ref() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined" >&2
        return 1
    }

    local ref="${1:-}"
    local -a candidates=()

    [[ -n "$ref" ]] || {
        echo "[Query] Empty note reference" >&2
        return 1
    }

    mapfile -t candidates < <(_resolve_note_ref_candidates "$ref")

    [[ ${#candidates[@]} -gt 0 ]] || {
        echo "[Query] Note not found: $ref" >&2
        return 1
    }

    local first_line="${candidates[0]}"
    local first_id first_path first_title first_updated first_priority
    IFS=$'\t' read -r first_id first_path first_title first_updated first_priority <<< "$first_line"

    [[ -n "${first_priority:-}" ]] || {
        echo "[Query] Failed to resolve note reference: $ref" >&2
        return 1
    }

    local tie_count=0
    local line id path title updated priority
    local ambiguity_lines=""

    for line in "${candidates[@]}"; do
        IFS=$'\t' read -r id path title updated priority <<< "$line"
        [[ "${priority:-}" == "$first_priority" ]] || break

        tie_count=$((tie_count + 1))
        if (( tie_count <= 5 )); then
            ambiguity_lines+=" - ${title:-\"(untitled)\"} | ${path}"$'\n'
        fi
    done

    if (( tie_count > 1 )); then
        printf '[Query] Ambiguous note reference: %s\n' "$ref" >&2
        printf '[Query] Matching candidates:\n' >&2
        printf '%s' "$ambiguity_lines" >&2
        return 1
    fi

    printf '%s\t%s\t%s\t%s\n'         "$first_id"         "$first_path"         "$first_title"         "$first_updated"
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
# Graph Proximity Query
# ----------------------------------------------------------
# Input:
#   note id
# Output:
#   id<TAB>path<TAB>title<TAB>distance
#
# Semantics:
#   - direct graph neighbors only
#   - union of outgoing and incoming links
#   - deduplicated by note id
#   - deterministic ordering by path asc
#   - fixed distance = 1
# ----------------------------------------------------------

query_graph_proximity_by_note() {

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
WITH direct_neighbors AS (
    SELECT l.target_id AS neighbor_id
    FROM links l
    WHERE l.source_id = @id

    UNION

    SELECT l.source_id AS neighbor_id
    FROM links l
    WHERE l.target_id = @id
)
SELECT n.id,
       n.path,
       n.title,
       1 AS distance
FROM direct_neighbors d
JOIN notes n ON n.id = d.neighbor_id
WHERE n.id <> @id
ORDER BY n.path ASC;
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

# ----------------------------------------------------------
# Graph Context Query
# ----------------------------------------------------------
# Input:
#   note id
#   optional max depth (default: 3)
# Output:
#   id<TAB>path<TAB>title<TAB>distance
#
# Semantics:
#   - outgoing traversal only
#   - BFS shortest-path expansion
#   - deterministic adjacency order via path asc
#   - deterministic final ordering: distance asc, path asc
# ----------------------------------------------------------

query_graph_context_by_note() {

    [[ -n "${BRAIN_DB:-}" ]] || {
        echo "[Query] BRAIN_DB not defined" >&2
        return 1
    }

    local note_id="${1:-}"
    local max_depth="${2:-3}"

    [[ "$note_id" =~ ^[0-9]+$ ]] || {
        echo "[Query] Invalid note id: $note_id" >&2
        return 1
    }

    [[ "$max_depth" =~ ^[0-9]+$ ]] || max_depth="3"
    (( max_depth >= 1 )) || max_depth=1

    declare -A visited=()
    declare -A node_distance=()
    declare -A node_path=()
    declare -A node_title=()

    local -a queue_ids=()
    local -a queue_depths=()

    local head=0
    local current_id=""
    local current_depth=""
    local next_id=""
    local next_path=""
    local next_title=""
    local discovered_id=""

    visited["$note_id"]=1
    queue_ids+=("$note_id")
    queue_depths+=(0)

    while (( head < ${#queue_ids[@]} )); do
        current_id="${queue_ids[$head]}"
        current_depth="${queue_depths[$head]}"
        head=$((head + 1))

        if (( current_depth >= max_depth )); then
            continue
        fi

        while IFS=$'\t' read -r next_id next_path next_title; do
            [[ -n "${next_id:-}" ]] || continue
            [[ "$next_id" =~ ^[0-9]+$ ]] || continue

            if [[ -n "${visited[$next_id]:-}" ]]; then
                continue
            fi

            visited["$next_id"]=1
            node_distance["$next_id"]=$((current_depth + 1))
            node_path["$next_id"]="$next_path"
            node_title["$next_id"]="$next_title"

            queue_ids+=("$next_id")
            queue_depths+=($((current_depth + 1)))
        done < <(query_adjacent_note_ids "$current_id")
    done

    for discovered_id in "${!node_distance[@]}"; do
        printf "%s\t%s\t%s\t%s\n" \
            "$discovered_id" \
            "${node_path[$discovered_id]}" \
            "${node_title[$discovered_id]}" \
            "${node_distance[$discovered_id]}"
    done | sort -t $'\t' -k4,4n -k2,2
}
