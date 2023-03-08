# GDNative Ropesim

A 2D verlet integration based rope simulation for Godot 3.x. Written in C++ using GDNative for fast performance.

The computation-heavy simulation part is written in C++, the rest in GDscript. This allows for fast processing and easy extendability, while keeping the code readable.

# Setup

1. Clone or download the repository
2. Run `git submodule update --init --recursive`
3. Get the library
    * [Build](#building) it yourself or
    * [Download](https://github.com/mphe/GDNative-Ropesim/actions) it from the latest Github Actions workflow run and put all contained files in `demo/addons/ropesim/bin/`.
4. Copy or symlink `demo/addons` to your project or use the provided demo project.
5. Enable the addon in the project settings
6. Restart Godot

# Building

See [here](https://docs.godotengine.org/en/stable/tutorials/scripting/gdnative/gdnative_cpp_example.html) on how to compile GDNative libraries.

Output files are saved to `demo/addons/ropesim/bin/`.

E.g. to compile for Linux:
```sh
$ cd godot-cpp
$ scons platform=linux generate_bindings=yes -j8 bits=64 target=release
$ cd ..
$ scons platform=linux -j8 target=release "$@"
```

You can use the provided scripts to build for Linux and Windows.

1. `./compile_bindings.sh`
2. `./compile.sh`


# Documentation

Following nodes exist:
* `Rope`: The basic rope node. Optionally renders the rope using `draw_polyline()`.
* `RopeAnchor`: Always snaps to the specified position on the target rope. Optionally, also adapts to the rope's curvature. Can be used to attach objects to a rope.
* `RopeHandle`: A handle that can be used to control, animate, or fixate parts of the rope.
* `RopeRendererLine2D`: Renders a target rope using `Line2D`.

See inline comments for documentation of node properties.

When one of these nodes is selected, a "Ropesim" menu appears in the editor toolbar that can be used to toggle live preview in the editor on and off.

All rope related tools, automatically pause themselves when their target rope is paused to save performance.

# Showcase

A quick overview of how to use each node.

https://user-images.githubusercontent.com/7116001/216790870-4e57fce0-7981-44f5-9963-daa1d9751abf.mp4



Jellyfish with rope simulated tentacles.

https://user-images.githubusercontent.com/7116001/216791913-35321ddb-ee35-44e2-85ba-0632a1123fda.mp4
