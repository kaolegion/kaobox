LOG_FILE="/var/log/kaobox/brain.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$LOG_FILE"
}
