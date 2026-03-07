#!/usr/bin/env bash
set -e

echo "Testing brain status"
brain status

echo "Testing brain doctor"
brain doctor

echo "Testing note creation"
brain new "test note"

echo "Testing search"
brain search test

echo "All tests passed"
