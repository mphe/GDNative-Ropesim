#!python
#!/usr/bin/env python
# type: ignore
# pylint: disable-all
# flake8: noqa

import os
import sys
import subprocess

PROJECT_NAME = "libropesim"
TARGET_PATH = f"demo/addons/ropesim/bin/{PROJECT_NAME}"

env = SConscript("godot-cpp/SConstruct")

# Options
opts = Variables([], ARGUMENTS)
opts.Update(env)

# Flags
# For reference:
# - CCFLAGS are compilation flags shared between C and C++
# - CFLAGS are for C-specific compilation flags
# - CXXFLAGS are for C++-specific compilation flags
# - CPPFLAGS are for pre-processor flags
# - CPPDEFINES are for pre-processor defines
# - LINKFLAGS are for linking flags


# Sources
env.Append(CPPPATH=["src/"])
sources = Glob("src/*.cpp")


# Build
if env["platform"] == "macos":
    # NOTE: This is from the Godot docs, but why do we need to do this on macos?
    library = env.SharedLibrary(
        f"{TARGET_PATH}.{env['platform']}.{env['target']}.framework/{PROJECT_NAME}.{env['platform']}.{env['target']}",
        source=sources
    )
else:
    library = env.SharedLibrary(f"{TARGET_PATH}{env['suffix']}{env['SHLIBSUFFIX']}", source=sources)

Default(library)
