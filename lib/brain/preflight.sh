preflight_check() {
    if [ ! -f "$BRAIN_DB" ]; then
        echo "Brain database not found at $BRAIN_DB"
        exit 1
    fi
}
