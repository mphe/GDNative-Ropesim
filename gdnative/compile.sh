#!/usr/bin/env bash
cd "$(dirname "$(readlink -f "$0")")" || exit 1

scons platform=windows -j8 target=release "$@"
scons platform=linux -j8 target=release "$@"
# scons platform=osx -j8 target=release "$@"
