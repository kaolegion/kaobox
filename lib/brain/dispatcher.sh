usage() {
    echo "Usage:"
    echo "  brain new \"Title\""
    echo "  brain search <query>"
    echo "  brain search tag:<tag>"
    echo "  brain open <filename>"
    echo "  brain ls"
    echo "  brain reindex"
    echo "  brain doctor"
    exit 1
}

dispatch() {

    case "$1" in
        search) shift; cmd_search "$@" ;;
        new) shift; cmd_new "$@" ;;
        open) shift; cmd_open "$@" ;;
        ls) cmd_ls ;;
        doctor) cmd_doctor ;;
        reindex) cmd_reindex ;;
        help) usage ;;
        "") cmd_fuzzy ;;
        *) cmd_search "$1" ;;
    esac
}
