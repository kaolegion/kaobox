#!/usr/bin/env bash
# ==========================================================
# KaoBox Brain - Explain Command (Observability)
# ==========================================================

[[ -n "${BRAIN_EXPLAIN_CMD_LOADED:-}" ]] && return 0
readonly BRAIN_EXPLAIN_CMD_LOADED=1

_explain_usage() {
    log_error "Usage: brain explain [--trace] <query>"
}

cmd_explain() {

    local trace=0
    local query=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --trace) trace=1; shift ;;
            -h|--help|help) _explain_usage; return 0 ;;
            *) query="${query}${query:+ }$1"; shift ;;
        esac
    done

    [[ -z "${query:-}" ]] && { _explain_usage; return 1; }

    [[ -n "${BRAIN_DB:-}" ]] || { log_error "BRAIN_DB not defined"; return 1; }
    [[ -f "$BRAIN_DB" ]] || { log_error "Brain DB not found: $BRAIN_DB"; return 1; }

    local safe_query="$query"
    if declare -f sanitize_fts >/dev/null 2>&1; then
        safe_query="$(sanitize_fts "$query")"
    fi
    [[ -z "${safe_query:-}" ]] && { log_error "Query became empty after sanitization"; return 1; }

    log_info "Explaining query: $safe_query"

    echo "EXPLAIN"
    echo "----------------------------------------"
    echo "Query : $safe_query"
    echo "Limit : 5"

    if (( trace == 1 )); then
        echo
        echo "PLAN"
        echo "----------------------------------------"
        sqlite3 -batch -noheader -separator $'\t' "$BRAIN_DB" <<SQL | sed 's/^/  /'
.parameter init
.parameter set @q "$safe_query"
EXPLAIN QUERY PLAN
SELECT n.path,
       bm25(notes_fts) AS score
FROM notes_fts
JOIN notes n ON n.rowid = notes_fts.rowid
WHERE notes_fts MATCH @q
ORDER BY score
LIMIT 5;
SQL
    fi

    echo
    echo "RESULTS"
    echo "----------------------------------------"

    local -a rows=()
    mapfile -t rows < <(
        sqlite3 -batch -noheader -separator $'\t' "$BRAIN_DB" <<SQL
.parameter init
.parameter set @q "$safe_query"
SELECT n.path,
       bm25(notes_fts) AS score
FROM notes_fts
JOIN notes n ON n.rowid = notes_fts.rowid
WHERE notes_fts MATCH @q
ORDER BY score
LIMIT 5;
SQL
    )

    if [[ ${#rows[@]} -eq 0 ]]; then
        echo "No results."
        return 0
    fi

    local row path score
    for row in "${rows[@]}"; do
        IFS=$'\t' read -r path score <<< "$row"
        [[ -z "${path:-}" ]] && continue
        echo "Path      : $path"
        echo "FTS score : $score"
        echo
    done
}
