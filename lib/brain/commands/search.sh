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
