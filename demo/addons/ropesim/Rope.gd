@tool
extends Node2D
class_name Rope

# TODO: Split line rendering into a separate node

signal on_registered()
signal on_unregistered()

@export var pause: bool = false: set = _set_pause
@export var num_segments: int = 10: set = _set_num_segs
@export var rope_length: float = 100: set = _set_length
@export var segment_length_distribution: Curve: set = _set_seg_dist
@export var stiffness: float = 0.0  # Stiffness forces the rope to return to its resting position.
@export var gravity: float = 100  # Gravity
@export var damping: float = 0  # Friction
@export var damping_curve: Curve  # (Optional) Apply different amounts of damping along the rope.
@export var num_constraint_iterations: int = 10  # Constraints the rope to its intended length. Less constraint iterations effectively makes the rope more elastic.

@export var render_debug: bool = false: set = _set_draw_debug
@export var render_line: bool = true: set = _set_render_line
@export var line_width: float = 2: set = _set_line_width
@export var color: Color = Color.WHITE: set = _set_color
@export var color_gradient: Gradient: set = _set_gradient

var _colors := PackedColorArray()
var _seg_lengths := PackedFloat32Array()
var _points := PackedVector2Array()
var _oldpoints := PackedVector2Array()
var _registered: bool = false


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
        _points[0] = global_position
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


func _register_server():
    if not _registered:
        NativeRopeServer.register_rope(self)
        emit_signal("on_registered")
        if render_debug or render_line:
            NativeRopeServer.connect("on_post_update", Callable(self, "_on_post_update"))  # warning-ignore: return_value_discarded
        _registered = true


func _unregister_server():
    if _registered:
        NativeRopeServer.unregister_rope(self)
        emit_signal("on_unregistered")
        if NativeRopeServer.is_connected("on_post_update", Callable(self, "_on_post_update")):
            NativeRopeServer.disconnect("on_post_update", Callable(self, "_on_post_update"))
        _registered = false


# Cache line colors according to color and color_gradient.
# Usually, you should not need to call this manually.
func update_colors():
    if not color_gradient:
        return

    if _colors.size() != _points.size():
        _colors.resize(_points.size())

    for i in _colors.size():
        _colors[i] = color * color_gradient.sample(get_point_perc(i))

    queue_redraw()


# Recompute segment lengths according to rope_length, num_segments and segment_length_distribution curve.
# Usually, you should not need to call this manually.
func update_segments():
    if _seg_lengths.size() != num_segments:
        _seg_lengths.resize(num_segments)

    if segment_length_distribution:
        var length = 0.0

        for i in _seg_lengths.size():
            _seg_lengths[i] = segment_length_distribution.sample(get_point_perc(i + 1))
            length += _seg_lengths[i]

        var scaling = rope_length / length

        for i in _seg_lengths.size():
            _seg_lengths[i] *= scaling
    else:
        var base_seg_length = rope_length / num_segments
        for i in _seg_lengths.size():
            _seg_lengths[i] = base_seg_length



# Access

func get_num_points() -> int:
    return _points.size()


func get_point_index(position_percent: float) -> int:
    return int((get_num_points() - 1) * clamp(position_percent, 0, 1))


func get_point_perc(index: int) -> float:
    return index / float(_points.size() - 1) if _points.size() > 0 else 0.0


func get_point_interpolate(position_perc: float) -> Vector2:
    var idx := get_point_index(position_perc)
    if idx == _points.size() - 1:
        return _points[idx]
    var next := idx + 1
    var next_perc := get_point_perc(next)
    var perc := get_point_perc(idx)
    return lerp(_points[idx], _points[next], (position_perc - perc) / (next_perc - perc))


func get_nearest_point_index(pos: Vector2) -> int:
    var min_dist = 1e10
    var idx = 0

    for i in _points.size():
        var dist = pos.distance_squared_to(_points[i])
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


# Makes a copy! PoolVector2Array is pass-by-value.
func get_points() -> PackedVector2Array:
    return _points


# Makes a copy! PoolVector2Array is pass-by-value.
func get_old_points() -> PackedVector2Array:
    return _oldpoints


func get_segment_length(segment_index: int) -> float:
    return _seg_lengths[segment_index]


func reset(dir: Vector2 = Vector2.DOWN) -> void:
    # TODO: Reset in global_transform direction
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


# Setters

func _set_num_segs(value: int):
    num_segments = value
    _setup(false)

func _set_length(value: float):
    rope_length = value
    _setup(false)

func _set_draw_debug(value: bool):
    render_debug = value
    _start_stop_rendering()

func _set_render_line(value: bool):
    render_line = value
    _start_stop_rendering()

func _set_line_width(value: float):
    line_width = value
    queue_redraw()

func _set_color(value: Color):
    color = value
    update_colors()

func _set_pause(value: bool):
    pause = value
    _start_stop_process()

func _set_gradient(value: Gradient):
    if color_gradient:
        color_gradient.disconnect("changed", Callable(self, "update_colors"))
    color_gradient = value
    if color_gradient:
        color_gradient.connect("changed", Callable(self, "update_colors"))  # warning-ignore: return_value_discarded
    update_colors()

func _set_seg_dist(value: Curve):
    if segment_length_distribution:
        segment_length_distribution.disconnect("changed", Callable(self, "update_segments"))
    segment_length_distribution = value
    if segment_length_distribution:
        segment_length_distribution.connect("changed", Callable(self, "update_segments"))  # warning-ignore: return_value_discarded
    update_segments()

