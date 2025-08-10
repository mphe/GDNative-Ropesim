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
