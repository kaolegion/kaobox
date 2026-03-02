LOCK_FILE="/tmp/kaobox-brain.lock"

acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        echo "Brain is already running."
        exit 1
    fi
    touch "$LOCK_FILE"
}

release_lock() {
    rm -f "$LOCK_FILE"
}

trap release_lock EXIT
