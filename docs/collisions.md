# Collisions

## Overview

At each rope point a circle collision check will be performed. If there is a collision, the rope point will be moved to a safe space.
This can cause the tunneling and stretching since only discrete areas are checked for collisions, not whole rope segments.
Usually, with relatively smooth topology, the circle colliders nicely slide along it, but with sharp corners, it will be very difficult to prevent stretching, because they effectively pierce between the colliders and separate them.

## Why Not Check Whole Segments?

Resolving collisions with whole rope segments would involve much more complex logic with respectively larger computation times.
That kinda defeats the purpose of this plugin.
The current implementation is simple, fast and good enough for most use-cases.
If perfect precision is needed, it's probably better to build a rope out of rigidbodies using built-in physics.

## Tweaking Collisions

The following properties can be tweaked to improve collision response:

- `num_segments`
- `num_constraint_iterations`
- `collision_radius`
- `resolve_collisions_while_constraining`

Also very helpful is `render_debug` as it will display the effective collider areas as cyan circles.
It helps visualizing how much space is covered by colliders and the effect of tuning the above properties (except the last one).

Increasing `num_segments` also increases the amount of collision tests, which results in more precise collision detection.
I found 10 segments per 100 pixel length a good value, but it very much depends on the use case.

Increasing `num_segments` will very likely also require increasing `num_constraint_iterations` as well to hold the rope together properly.
For `num_constraint_iterations` there is no rule of thumb. The less iterations, the stretchier the rope will become.
More iterations make the rope tighter and less bouncy/stretchy, but it will also increase computation time respectively.
More segments require more constraint iterations to keep the rope equally tight.
When increasing constraint iterations the rope's length becomes closer to `rope_length` and the colliders move closer together, reducing the gap between them.

`collision_radius` is the radius of the colliders. Larger colliders cover more space and thus reduce tunneling/stretching. It can't solve it completely, though.
There is also no rule of thumb, you have to play around with it until you find a sweet spot.

Finally, `resolve_collisions_while_constraining` helps a lot to reduce tunneling/stretching by running the collision test after every single constraint iteration instead of once after the constraint step finished.
Consequently, it also drastically affects the computation time in relation to `num_constraint_iterations`.
With only a few ropes, it's fine, but with many ropes it can tank the framerate.

As for balancing computation cost, keep an eye on `NativeRopeServer.get_computation_time()`.
There is a script `rope_examples/scripts/PerformanceLabel.gd` that can be used.
