# LANCHER-INIT

#!/usr/bin/env bash

KAOBOX_DIR="/opt/kaobox"

# Load i18n first
source "$KAOBOX_DIR/core/i18n.sh"

# Launch core init
exec "$KAOBOX_DIR/core/init.sh"
