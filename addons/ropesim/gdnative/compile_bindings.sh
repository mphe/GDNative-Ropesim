#!/usr/bin/env bash

# arg1: platform
build() {
    echo
    echo "Building for $1"
    echo Building debug
    scons platform="$1" generate_bindings=yes -j8 bits=64
    echo Building release
    scons platform="$1" generate_bindings=yes -j8 bits=64 target=release
}

cd "$(dirname "$(readlink -f "$0")")" || exit 1
cd godot-cpp || exit 1

build linux
build windows
build osx
