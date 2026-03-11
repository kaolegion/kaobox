#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# KAOBOX - Global Test Runner
# ----------------------------------------------------------
# Goal:
#   - Run the full deterministic test suite
#   - Stop immediately on first failure
#   - Keep execution order explicit and auditable
# ==========================================================

echo "[RUN] KaoBox test suite"

# ----------------------------------------------------------
# Core
# ----------------------------------------------------------
echo "[RUN] test_logger.sh"
./tests/test_logger.sh

# ----------------------------------------------------------
# Memory
# ----------------------------------------------------------
echo "[RUN] test_memory_index.sh"
./tests/test_memory_index.sh

# ----------------------------------------------------------
# Graph
# ----------------------------------------------------------
echo "[RUN] test_graph_navigation.sh"
./tests/test_graph_navigation.sh

echo "[RUN] test_graph_path.sh"
./tests/test_graph_path.sh

echo "[RUN] test_graph_proximity.sh"
./tests/test_graph_proximity.sh

echo "[RUN] test_note_ref_resolution.sh"
./tests/test_note_ref_resolution.sh

echo "[RUN] test_graph_related.sh"
./tests/test_graph_related.sh

echo "[RUN] test_graph_export.sh"
./tests/test_graph_export.sh

echo "[RUN] test_graph_export_cli.sh"
./tests/test_graph_export_cli.sh

# ----------------------------------------------------------
# Cognition
# ----------------------------------------------------------
echo "[RUN] test_think_graph_boost.sh"
./tests/test_think_graph_boost.sh

# ----------------------------------------------------------
# CLI
# ----------------------------------------------------------
echo "[RUN] test_brain_cli.sh"
./tests/test_brain_cli.sh

echo "[RUN] test_cli_regression_contract.sh"
./tests/test_cli_regression_contract.sh

echo "[SUCCESS] All tests passed"
