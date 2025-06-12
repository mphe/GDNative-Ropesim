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

if os.name == "posix":
    env.Append(CCFLAGS="-fdiagnostics-color")


scons_cache_path = os.environ.get("SCONS_CACHE")
if scons_cache_path:
    os.makedirs(scons_cache_path, exist_ok=True)
    CacheDir(scons_cache_path)
    print("Using cache dir:", scons_cache_path)


# Sources
env.Append(CPPPATH=["src/"])
sources = Glob("src/*.cpp")

# Docs
if env["target"] in ["editor", "template_debug"]:
    try:
        doc_data = env.GodotCPPDocData("src/gen/doc_data.gen.cpp", source=Glob("doc_classes/*.xml"))
        sources.append(doc_data)
    except AttributeError:
        print("Not including class reference as we're targeting a pre-4.3 baseline.")

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
