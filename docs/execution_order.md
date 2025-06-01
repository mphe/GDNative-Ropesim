# Execution Order

Ropes are not processed by their node but in the `NativeRopeServer` class, which executes at the start of the physics frame, i.e. when the `SceneTree.physics_frame` signal runs.

Roughly sketched, the order looks like this:

1. `SceneTree.physics_frame`
    - Rope update
2. `_process()`
3. `_physics_process()`

This assumes that the FPS match the physics tickrate, which is usually locked at 60 FPS.
On a 144 Hz screen for example, it wouldn't match and you get more `_process()` frames than `_physics_process()` possibly making this lag even more noticable.

`NativeRopeServer` provides a set of signals for fine-tuned execution order handling:

- `on_pre_update`
- `on_pre_pre_update`
- `on_post_update`
- `on_post_post_update.`

They get emitted just before/after rope updates.

1. `SceneTree.physics_frame`
    1. `on_pre_pre_update`
    2. `on_pre_update`
    3. Rope update
    4. `on_post_update`
    5. `on_post_post_update`
2. `_process()`
3. `_physics_process()`

These signals are also used by various rope utilities like `RopeAnchor`, `RopeHandle` or `RopeRendererLine2D` to update the rope's properties or their own just before/after rope updates occur.
At the moment they use the normal `pre` and `post` signals, not `pre_pre` or `post_post`.

## Solving the One-Frame Delay

Updating the rope position in `_process()` or `_physics_process()` causes a one-frame delay because they run after the rope has already been updated.
Hence, the result is only visible in the next frame.

The workaround is to connect to `NativeRopeServer.on_pre_pre_update` and update the rope's position there.
It can essentially be treated as a kind of `_physics_process()` which runs just before rope updates.

You can take a look at the `rope_pulling.tscn` example.
The player node there uses the same approach.
