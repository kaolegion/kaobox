usage() {
    echo "Usage:"
    echo "  brain new \"Title\""
    echo "  brain search <query>"
    echo "  brain search tag:<tag>"
    echo "  brain open <filename>"
    echo "  brain ls"
    echo "  brain reindex"
    echo "  brain doctor"
    exit 0
}

dispatch() {
    local cmd="${1:-}"

    if [[ -z "$cmd" ]]; then
        cmd_fuzzy
        return
    fi

    case "$cmd" in
        search) shift; cmd_search "$@" ;;
        new) shift; cmd_new "$@" ;;
        open) shift; cmd_open "$@" ;;
        ls) cmd_ls ;;
        doctor) cmd_doctor ;;
        reindex) cmd_reindex ;;
        help) usage ;;
        *) cmd_search "$cmd" ;;
    esac
}
