#!/usr/bin/env bash
cd "$(dirname "$(readlink -f "$0")")" || exit 1

scons platform=windows -j8 target=debug "$@"
scons platform=linux -j8 target=debug "$@"
# scons platform=osx -j8 target=debug "$@"
