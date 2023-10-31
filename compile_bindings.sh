#!/usr/bin/env bash

cd "$(dirname "$(readlink -f "$0")")" || exit 1

cd godot-cpp || exit 1
scons platform=linux -j8 bits=64 target=release
scons platform=windows -j8 bits=64 target=release
