#!/usr/bin/env bash
set -euo pipefail

echo "[RUN] test_logger.sh"
./tests/test_logger.sh

echo "[RUN] test_memory_index.sh"
./tests/test_memory_index.sh

echo "[RUN] test_graph_navigation.sh"
./tests/test_graph_navigation.sh

echo "[RUN] test_graph_path.sh"
./tests/test_graph_path.sh

echo "[RUN] test_graph_proximity.sh"
./tests/test_graph_proximity.sh

echo "[RUN] test_graph_export.sh"
./tests/test_graph_export.sh

echo "[RUN] test_think_graph_boost.sh"
./tests/test_think_graph_boost.sh

echo "[RUN] test_brain_cli.sh"
./tests/test_brain_cli.sh

echo "[SUCCESS] All tests passed"
