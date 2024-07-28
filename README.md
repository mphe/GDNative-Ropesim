# GDNative Ropesim

<img src="https://github.com/mphe/GDNative-Ropesim/assets/7116001/272f4f65-cb79-4798-97ba-f0d43589caef" width=128px align="right"/>

A 2D verlet integration based rope simulation for Godot 4.2+.

The computation-heavy simulation part is written in C++ using GDExtension, the rest in GDScript. This allows for fast processing and easy extendability, while keeping the code readable.

The last Godot 3.x version can be found on the [3.x branch](https://github.com/mphe/GDNative-Ropesim/tree/3.x), however, this branch will no longer receive updates.

## Setup

1. Get the addon
    * [Download](https://godotengine.org/asset-library/asset/2334) from the asset store, or
    * [Download](https://github.com/mphe/GDNative-Ropesim/releases/latest) the latest release from the release page, or
    * [Download](https://github.com/mphe/GDNative-Ropesim/actions) it from the latest GitHub Actions run, or
    * [Compile](#building) it yourself.
2. Copy or symlink `addons/ropesim` to your project's `addons/` directory
3. Enable the addon in the project settings
4. Restart Godot

## Building

First, clone or download the repository and run `git submodule update --init --recursive`.

See [here](https://docs.godotengine.org/en/latest/tutorials/scripting/gdextension/gdextension_cpp_example.html#doc-gdextension-cpp-example) on how to create and compile GDExtension libraries.

To compile for Linux, run the following commands.
Compiling for other platforms works analogously.

```sh
$ scons target=template_release platform=linux optimize=speed arch=x86_64 -j8
$ scons target=template_debug platform=linux arch=x86_64 -j8
```

Output files are saved to `demo/addons/ropesim/bin/`.

## Documentation and Usage

### Nodes

The following nodes exist:
* `Rope`: The basic rope node. Optionally renders the rope using `draw_polyline()`.
* `RopeAnchor`: Always snaps to the specified position on the target rope. Optionally, also adapts to the rope's curvature. Can be used to attach objects to a rope.
* `RopeHandle`: A handle that can be used to control, animate, or fixate parts of the rope.
* `RopeRendererLine2D`: Renders a target rope using `Line2D`.
* `RopeCollisionShapeGenerator`: Can be used e.g. in an `Area2D` to detect collisions with the target rope.
* `RopeInteraction`: Handles mutual interaction of a target node with a rope. Useful for rope grabbing or pulling mechanics where an object should be able to affect the rope and vice-versa.

**NOTE:** All rope related tools automatically pause themselves when their target rope is paused to reduce computation costs and improve performance.

Use the in-engine help to view the full documentation for each node.

### Editor Menu
When one of the above nodes is selected, a "*Ropesim*" menu appears in the editor toolbar with the following options:
* `Preview in Editor`: Toggle live preview in the editor on or off.
* `Reset Rope`: Reset the selected rope to its resting position.

### Examples
The project includes various example scenes that demonstrate the features of this plugin.
See also the [showcase video](#showcase) for a basic usage example.

## Showcase

A quick overview of how to use each node.

https://user-images.githubusercontent.com/7116001/216790870-4e57fce0-7981-44f5-9963-daa1d9751abf.mp4



Jellyfish with rope simulated tentacles.

https://user-images.githubusercontent.com/7116001/216791913-35321ddb-ee35-44e2-85ba-0632a1123fda.mp4



More advanced usage examples.

https://github.com/user-attachments/assets/28e3dda1-6929-4ddf-8afa-041f66a5849b


