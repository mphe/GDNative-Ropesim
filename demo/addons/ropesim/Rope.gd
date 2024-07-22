@tool
extends Node2D
class_name Rope

# TODO: Split line rendering into a separate node

## Triggered when the rope has been registered at the NativeRopeServer.
signal on_registered()

## Triggered when the rope has been unregistered from the NativeRopeServer.
signal on_unregistered()

## Triggered when the point count changes, i.e. when the number of segments changes.
signal on_point_count_changed()


## Pause the simulation.
@export var pause: bool = false: set = _set_pause

## Number of rope segments. More segments results in smoother quality but also higher computation cost.
@export var num_segments: int = 10: set = _set_num_segs

## Overall rope length. Will be distributed uniformly among all segments.
@export var rope_length: float = 100: set = _set_length

## Maximum euclidean distance between rope endpoints. Zero or negative for no limitation.
## This is an approximation and not 100% accurate.
## It is intended as a simple way to constraint the rope length when both endpoints are fixed by a RopeHandle.
## The actual length of the rope might differ depending on the number of constraint iterations.
## Fixed points in between are not taken into account.
@export var max_endpoint_distance: float = -1

## (Optional) Allows to distribute the length of rope segment in a non-uniform manner.
## Useful when certain parts of the rope should be more detailed than the rest.
## For example, if it is known that most movement happens at the beginning of the rope, a curve with
## smaller values at the beginning and larger values towards the end can improve the overall quality
## significantly by providing more segments at the beginning and less segments to the end.
@export var segment_length_distribution: Curve: set = _set_seg_dist

## Stiffness forces the rope to return to its resting position.
## The resting direction is downwards and affected by the the node's rotation.
## Might not produce 100% realistic results with fixed points.
@export var stiffness: float = 0.0

## Gravity
@export var gravity: float = 100

## Gravity direction. Will not be normalized.
@export var gravity_direction: Vector2 = Vector2.DOWN

## Dampens the velocity of the rope.
@export var damping: float = 0

## (Optional) Apply different amounts of damping along the rope.
@export var damping_curve: Curve

## Constraints the rope to its intended length. Less constraint iterations effectively makes the rope more elastic.
@export_range(0, 1000) var num_constraint_iterations: int = 10

## Whether to fixate the first point at the rope's node position.
@export var fixate_begin: bool = true

## Render rope points for debugging purposes.
@export var render_debug: bool = false: set = _set_draw_debug

## Render the rope as line.
@export var render_line: bool = true: set = _set_render_line

## Rendered line width.
@export var line_width: float = 2: set = _set_line_width

## Rendered line color.
@export var color: Color = Color.WHITE: set = _set_color

## Color gradient along the rendered line.
@export var color_gradient: Gradient: set = _set_gradient

var _registered: bool = false
var _colors := PackedColorArray()
var _seg_lengths := PackedFloat32Array()
var _points := PackedVector2Array()
var _oldpoints := PackedVector2Array()
# NOTE: Not @exported on purpose to prevent accidentally saving a scene with unintended weights, e.g. due to bugs or user errors.
var _simulation_weights := PackedFloat32Array()


# General

func _enter_tree() -> void:
    _setup()

    if Engine.physics_ticks_per_second != 60:
        push_warning("Verlet Integration is FPS dependant -> Only 60 FPS are supported")


func _exit_tree() -> void:
    _unregister_server()


func _on_post_update() -> void:
    if visible:
        queue_redraw()


func _draw() -> void:
    draw_set_transform_matrix(get_global_transform().affine_inverse())

    if render_line and _points.size() > 1:
        if color_gradient:
            draw_polyline_colors(_points, _colors, line_width)
        else:
            draw_polyline(_points, color, line_width)

    if render_debug:
        for i in _points.size():
            draw_circle(_points[i], line_width / 2, Color.RED)


# Logic

func _setup(run_reset: bool = true) -> void:
    if not is_inside_tree():
        return

    _points.resize(num_segments + 1)
    _oldpoints.resize(num_segments + 1)
    _resize_with_default(_simulation_weights, num_segments + 1, 1.0)

    update_colors()
    update_segments()

    if damping_curve:
        # NOTE: As long as the Curve is not modified during runtime, it should be fine.
        # if not damping_curve.get_local_scene():
        #     push_warning("Damping curve should be local to scene, otherwise it could lead to crashes due to multi-threading when it is change during runtime.")

        # NOTE: We probably shouldn't override user settings, even though it could
        # save some work from the user.
        # if damping_curve.bake_resolution != _points.size():
        #     damping_curve.bake_resolution = _points.size()

        # Force bake() here to prevent possible crashes when the Curve is baked
        # during simulation. Since Resource access is not thread-safe, it will
        # crash when multiple threads try to access or bake the Curve
        # simultaneously.
        damping_curve.bake()

    if run_reset:
        reset()
    _start_stop_process()


func _start_stop_process() -> void:
    if is_inside_tree() and not pause:
        _register_server()
    else:
        _unregister_server()


func _start_stop_rendering() -> void:
    # Re-register (or not) to hook NativeRopeServer.on_post_update() if neccessary.
    _unregister_server()
    _start_stop_process()
    queue_redraw()


func _register_server() -> void:
    if not _registered:
        NativeRopeServer.register_rope(self)
        on_registered.emit()
        if render_debug or render_line:
            NativeRopeServer.on_post_update.connect(_on_post_update)
        _registered = true


func _unregister_server() -> void:
    if _registered:
        NativeRopeServer.unregister_rope(self)
        on_unregistered.emit()
        if NativeRopeServer.on_post_update.is_connected(_on_post_update):
            NativeRopeServer.on_post_update.disconnect(_on_post_update)
        _registered = false


# Cache line colors according to color and color_gradient.
# Usually, you should not need to call this manually.
func update_colors() -> void:
    if not color_gradient:
        return

    if _colors.size() != _points.size():
        _colors.resize(_points.size())

    for i in _colors.size():
        _colors[i] = color * color_gradient.sample(get_point_perc(i))

    queue_redraw()


# Recompute segment lengths according to rope_length, num_segments and segment_length_distribution curve.
# Usually, you should not need to call this manually.
func update_segments() -> void:
    if _seg_lengths.size() != num_segments:
        _seg_lengths.resize(num_segments)

    if segment_length_distribution and segment_length_distribution.point_count > 0:
        var length := 0.0

        for i in _seg_lengths.size():
            _seg_lengths[i] = segment_length_distribution.sample(get_point_perc(i + 1))
            length += _seg_lengths[i]

        var scaling := rope_length / length

        for i in _seg_lengths.size():
            _seg_lengths[i] *= scaling
    else:
        var base_seg_length := rope_length / num_segments
        for i in _seg_lengths.size():
            _seg_lengths[i] = base_seg_length



# Access

func get_num_points() -> int:
    return _points.size()


## Returns the point index at the given percentage (0.0 - 1.0) in related to the total amount of points of the rope.
## Does not incorporate segment lengths. If there is a rope with 10 points and the last segment
## spans 50% of the whole rope, then get_point_index(0.5) returns 4, not 9.
func get_point_index(position_percent: float) -> int:
    return int((get_num_points() - 1) * clampf(position_percent, 0, 1))


## Inverse of get_point_index(). Returns at which percentage the index is located.
## Does not incorporate segment lengths.
func get_point_perc(index: int) -> float:
    return index / float(_points.size() - 1) if _points.size() > 0 else 0.0


## Similar to get_point_index() but returns the coordinates of the point at the given position fraction.
## If the target position lies between two points, the result will be interpolated.
## Does not incorporate segment lengths.
func get_point_interpolate(position_perc: float) -> Vector2:
    var idx := get_point_index(position_perc)
    if idx == _points.size() - 1:
        return _points[idx]
    var next := idx + 1
    var next_perc := get_point_perc(next)
    var perc := get_point_perc(idx)
    return lerp(_points[idx], _points[next], (position_perc - perc) / (next_perc - perc))


## Returns the point index nearest to the given coordinates.
func get_nearest_point_index(pos: Vector2) -> int:
    var min_dist := 1e10
    var idx := 0

    for i in _points.size():
        var dist := pos.distance_squared_to(_points[i])
        if dist < min_dist:
            min_dist = dist
            idx = i

    return idx


func get_point(index: int) -> Vector2:
    return _points[index]


func set_point(index: int, point: Vector2) -> void:
    _points[index] = point


func move_point(index: int, vec: Vector2) -> void:
    _points[index] += vec


func get_points() -> PackedVector2Array:
    return _points


func get_old_points() -> PackedVector2Array:
    return _oldpoints


func get_segment_length(segment_index: int) -> float:
    return _seg_lengths[segment_index]


func reset(dir: Vector2 = Vector2.DOWN) -> void:
    # TODO: Reset in global_transform or gravity_direction direction
    _points[0] = (global_position if is_inside_tree() else position)
    for i in range(1, _points.size()):
        _points[i] = _points[i - 1] + dir * get_segment_length(i - 1)
    _oldpoints = _points
    queue_redraw()


func set_points(points: PackedVector2Array) -> void:
    _points = points


func set_old_points(points: PackedVector2Array) -> void:
    _oldpoints = points


func get_color(index: int) -> Color:
    if color_gradient:
        return _colors[index]
    return color


func get_segment_lengths() -> PackedFloat32Array:
    return _seg_lengths


## The simulation weight determines how much a point can be moved during the simulation/constraint phase.
## 0.0 means no movement at all, i.e. the point is fixed.
## 1.0 allows full movement.
func set_point_simulation_weight(index: int, weight: float) -> void:
    _simulation_weights[index] = clampf(weight, 0.0, 1.0)


func get_point_simulation_weight(index: int) -> float:
    return _simulation_weights[index]


# Setters

func _set_num_segs(value: int) -> void:
    if value == num_segments:
        return
    num_segments = value
    _setup(Engine.is_editor_hint())
    on_point_count_changed.emit()

func _set_length(value: float) -> void:
    rope_length = value
    _setup(Engine.is_editor_hint())

func _set_draw_debug(value: bool) -> void:
    render_debug = value
    _start_stop_rendering()

func _set_render_line(value: bool) -> void:
    render_line = value
    _start_stop_rendering()

func _set_line_width(value: float) -> void:
    line_width = value
    queue_redraw()

func _set_color(value: Color) -> void:
    color = value
    update_colors()
    queue_redraw()

func _set_pause(value: bool) -> void:
    pause = value
    _start_stop_process()

func _set_gradient(value: Gradient) -> void:
    if color_gradient:
        color_gradient.changed.disconnect(update_colors)
    color_gradient = value
    if color_gradient:
        color_gradient.changed.connect(update_colors)
    update_colors()

func _set_seg_dist(value: Curve) -> void:
    if segment_length_distribution:
        segment_length_distribution.changed.disconnect(update_segments)
    segment_length_distribution = value
    if segment_length_distribution:
        segment_length_distribution.changed.connect(update_segments)
    update_segments()


func _resize_with_default(arr: PackedFloat32Array, new_size: int, default: float) -> void:
    var oldsize := arr.size()
    arr.resize(new_size)

    for i in range(oldsize, new_size):
        arr[i] = default
