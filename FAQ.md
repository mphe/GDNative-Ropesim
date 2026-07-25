# FAQ / Troubleshooting

## Textures do not tile in `RopeRendererLine2D`

Enable texture repeat under "CanvasItem → Texture → Repeat → Enabled".

See also [#28](https://github.com/mphe/GDNative-Ropesim/issues/28).


## Is Web export supported?

Yes, partially.
The plugin includes a web build, but since it uses GDExtension, a web export template with GDExtension support is required to use it.

According to the [Godot documentation](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_web.html#gdextension) for web:
> "The default export templates do not include GDExtension support for performance and compatibility reasons".

That means in order to use the web version of this plugin, you will need a custom web export template compiled with `dlink_enabled=yes`.

To compile it yourself, refer to the official Godot documentation for further information: [Building from source](https://docs.godotengine.org/en/stable/contributing/development/compiling/index.html), [Compiling for the Web](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_web.html) and [Exporting for the Web](https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_web.html).

Alternatively, you can download prebuilt export templates from another trusted source.
For example, the [LimboAI addon](https://github.com/limbonaut/limboai) provides web export templates with GDExtension support.


## Ropes lag one frame behind

This is a known issue and related to execution order.

**TL;DR:** Connect to the `NativeRopeServer.on_pre_pre_update` signal and run the rope update code there. It is essentially an alternative to `_physics_process()` that runs just before ropes get updated.

See [Execution Order Documentation](docs/execution_order.md) for a more detailed explanation.


## Collisions tunnel through objects / stretch along corners

See [Collisions Documentation](docs/collisions.md).


## Collisions are not working with Rapier2D

Rapier2D is not supported.

- It does not report relevant collision information in editor, only at runtime. That means collisions don't work in the editor at all.
- It reports different results, e.g. collision normals, than Godot's physics implementation, yielding broken collision behavior for various shapes besides polygons.

See also [#41](https://github.com/mphe/GDNative-Ropesim/issues/41).


## Verlet Integration is FPS dependant -> Only 60 FPS are supported

This warning appears when running a different physics tick rate than 60.

The code is only partially frame rate independent.
Increasing FPS makes the simulation run more often, decreasing FPS makes it run less often.
The overall behavior might be mostly identical, but it will be sped up or slowed down respectively.
For example, if the rope swings one time back and forth in one second at 60 FPS, it will do the same in only 0.5 seconds at 120 FPS.
Some parts of the simulation are FPS independent, like gravity or damping which lessens the effect, but this is not the case in general.

In contrast to common Euler based physics engines, this plugin does not continuously integrate forces to handle velocities. It recomputes velocities every frame from the current state.
This has the advantage of a very simple and efficient implementation.

Velocities are determined using the position difference from the current to last frame for each rope point.
That means, the farther rope points are moved in one frame, the higher their velocities will be in the next frame and the stronger the reaction.
Since the output position is used directly for the next frame's input, a frame rate independent simulation is impossible.

Imagine multiplying velocities with `delta` when computing new point positions.
On higher frame rates, the rope points would move less because of smaller deltas, on lower frame rates they would move more.
Instead of making the simulation frame rate independent, `delta` would only act as a kind of damping factor because it only slows the movement down which subsequently affects the velocity computed in the next frame.

It's perfectly fine to use this plugin on other frame rates than 60, but you will get different behavior.
If it works for your use-case, feel free to remove the line producing the warning,
But be aware that you can't just switch frame rates and expect the same outcome.
