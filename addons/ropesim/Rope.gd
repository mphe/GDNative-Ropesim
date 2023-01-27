tool
extends RopeBase
class_name Rope

export var pause: bool = false setget _set_pause
export var draw_debug: bool = false setget _set_draw_debug
export var line_width: float = 2 setget _set_line_width
export var color: Color = Color.white setget _set_color
export var color_gradient: Gradient setget _set_gradient
export var render_in_editor: bool = false setget _set_preview
export var num_segments: int = 10 setget _set_num_segs
export var rope_length: float = 100 setget _set_length
export var segment_length_distribution: Curve setget _set_seg_dist
export var stiffness: float = 0.0
export var gravity: float = 100
export var damping: float = 0
export var damping_curve: Curve
export var num_constraint_iterations: int = 20
export var render_line: bool = true
export var auto_update_render: bool = false

var _colors := PoolColorArray()
var _seg_lengths := PoolRealArray()
var _points := PoolVector2Array()
var _oldpoints := PoolVector2Array()
var _registered: bool = false


# General

func _init() -> void:
    if Engine.editor_hint and is_inside_tree():
        _ready()


func _ready() -> void:
    _setup()
    if Engine.iterations_per_second != 60:
        push_warning("Verlet Integration is FPS dependant -> Only 60 FPS are supported")


func _enter_tree() -> void:
    _register_server()


func _exit_tree() -> void:
    _unregister_server()


func _physics_process(_delta: float) -> void:
    if visible:
        update()


func _draw() -> void:
    draw_set_transform_matrix(get_global_transform().affine_inverse())

    if render_line and _points.size() > 1:
        _points[0] = global_position
        if color_gradient:
            draw_polyline_colors(_points, _colors, line_width)
        else:
            draw_polyline(_points, color, line_width)

    if draw_debug:
        for i in _points.size():
            draw_circle(_points[i], line_width / 2, Color.red)


# Logic

func _setup() -> void:
    if not is_inside_tree():
        return
    _points.resize(num_segments + 1)
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
    reset()
    _start_stop_process()


func _start_stop_process() -> void:
    var should_simulate = not pause
    var should_render = not pause and (render_line or draw_debug) and ((Engine.editor_hint and render_in_editor) or (not Engine.editor_hint and auto_update_render))
    set_physics_process(should_render)
    if should_simulate:
        _register_server()
    else:
        _unregister_server()


func _auto_update():
    if Engine.editor_hint or auto_update_render or draw_debug:
        update()


func _register_server():
    if not _registered:
        NativeRopeServer.register_rope(self)
        _registered = true


func _unregister_server():
    if _registered:
        NativeRopeServer.unregister_rope(self)
        _registered = false


func update_colors():
    if not color_gradient:
        return
    if _colors.size() != _points.size():
        _colors.resize(_points.size())

    for i in _colors.size():
        _colors[i] = color * color_gradient.interpolate(get_point_perc(i))

    _auto_update()


func update_segments():
    if _seg_lengths.size() != num_segments:
        _seg_lengths.resize(num_segments)

    if segment_length_distribution:
        var length = 0.0

        for i in _seg_lengths.size():
            _seg_lengths[i] = segment_length_distribution.interpolate(get_point_perc(i + 1))
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
    return int((get_num_points() - 1) * position_percent)


func get_point_perc(index: int) -> float:
    return index / float(_points.size() - 1) if _points.size() > 0 else 0.0


func get_point(index: int) -> Vector2:
    return _points[index]


func set_point(index: int, point: Vector2) -> void:
    _points[index] = point


func move_point(index: int, vec: Vector2) -> void:
    _points[index] += vec


# Makes a copy! PoolVector2Array is pass-by-value.
func get_points() -> PoolVector2Array:
    return _points


# Makes a copy! PoolVector2Array is pass-by-value.
func get_old_points() -> PoolVector2Array:
    return _oldpoints


func get_segment_length(segment_index: int) -> float:
    return _seg_lengths[segment_index]


func reset(dir: Vector2 = Vector2.DOWN) -> void:
    # TODO: Reset in global_transform direction
    _points[0] = (global_position if is_inside_tree() else position)
    for i in range(1, _points.size()):
        _points[i] = _points[i - 1] + dir * get_segment_length(i - 1)
    _oldpoints = _points
    _auto_update()


func set_points(points: PoolVector2Array) -> void:
    _points = points

func set_old_points(points: PoolVector2Array) -> void:
    _oldpoints = points


func get_color(index: int) -> Color:
    if color_gradient:
        return _colors[index]
    return color


func get_segment_lengths() -> PoolRealArray:
    return _seg_lengths

# Setters

func _set_num_segs(value: int):
    num_segments = value
    _setup()

func _set_length(value: float):
    rope_length = value
    _setup()

func _set_preview(value: bool):
    render_in_editor = value
    _setup()

func _set_draw_debug(value: bool):
    draw_debug = value
    _auto_update()

func _set_line_width(value: float):
    line_width = value
    _auto_update()

func _set_color(value: Color):
    color = value
    update_colors()

func _set_pause(value: bool):
    pause = value
    _start_stop_process()

func _set_gradient(value: Gradient):
    if color_gradient:
        color_gradient.disconnect("changed", self, "update_colors")
    color_gradient = value
    if color_gradient:
        color_gradient.connect("changed", self, "update_colors")  # warning-ignore: return_value_discarded
    update_colors()

func _set_seg_dist(value: Curve):
    if segment_length_distribution:
        segment_length_distribution.disconnect("changed", self, "update_segments")
    segment_length_distribution = value
    if segment_length_distribution:
        segment_length_distribution.connect("changed", self, "update_segments")  # warning-ignore: return_value_discarded
    update_segments()

