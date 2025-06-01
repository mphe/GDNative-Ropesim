#!/usr/bin/env bash

SCONS_CACHE="$PWD/.scons_cache_debug" scons compiledb=yes optimize=debug use_llvm=yes debug_symbols=yes "$@"

# platform=web threads=no
