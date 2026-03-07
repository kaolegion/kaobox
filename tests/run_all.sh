#!/usr/bin/env bash
set -euo pipefail

echo "[RUN] test_logger.sh"
./tests/test_logger.sh

echo "[RUN] test_memory_index.sh"
./tests/test_memory_index.sh

echo "[RUN] test_brain_cli.sh"
./tests/test_brain_cli.sh

echo "[SUCCESS] All tests passed"
