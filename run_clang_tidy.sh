#!/usr/bin/env bash

cd "$(dirname "$(readlink -f "$0")")" || exit 1

echo "Checks: '-*'" > ./godot-cpp/.clang-tidy

if [ -t 0 ]; then
    run-clang-tidy -header-filter=src/ -allow-no-checks -use-color 1 -quiet "$@"
else
    run-clang-tidy -header-filter=src/ -allow-no-checks -quiet "$@"
fi
