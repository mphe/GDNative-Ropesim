@echo off
setlocal

set SCONS_CACHE=%CD%\.scons_cache_debug

scons compiledb=yes optimize=debug debug_symbols=yes %*

:: platform=web threads=no

endlocal