#!/usr/bin/env bash

SCONS_CACHE="$PWD/.scons_cache_debug" scons compiledb=yes optimize=debug use_llvm=yes "$@"

# platform=web threads=no
