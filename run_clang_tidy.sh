#!/usr/bin/env bash

cd "$(dirname "$(readlink -f "$0")")" || exit 1

clang-tidy src/*.cpp --config-file .clang-tidy -p .
