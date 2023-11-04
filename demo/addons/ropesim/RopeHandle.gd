@tool
extends Marker2D
class_name RopeHandle

# Gets emitted just before applying the position.
signal on_before_update()

@export var enable: bool = true: get = get_enable, set = set_enable  # Enable or disable
@export var rope_path: NodePath: set = set_rope_path
@export var rope_position = 1.0  # Position on the rope between 0 and 1. # (float, 0, 1)
@export var smoothing: bool = false  # Whether to smoothly snap to RopeHandle's position instead of instantly.
@export var position_smoothing_speed: float = 0.5  # Smoothing speed
## If false, only affect the nearest vertex on the rope. Otherwise, affect both surrounding points when applicable.
@export var precise: bool = false
var _helper: RopeToolHelper


func _init() -> void:
    if not _helper:
        _helper = RopeToolHelper.new(RopeToolHelper.UPDATE_HOOK_PRE, self, "_on_pre_update")
        add_child(_helper)


func _ready() -> void:
    set_rope_path(rope_path)
    set_enable(enable)


func _on_pre_update() -> void:
    emit_signal("on_before_update")
    var rope: Rope = _helper.target_rope
    var point_index: int = rope.get_point_index(rope_position)

    # Only use this method if this is not the last point.
    if precise and point_index < rope.get_num_points() - 1:
        # TODO: Consider creating a corresponding function in Rope.gd for universal access, e.g. set_point_interpolated().
        var point_pos: Vector2 = rope.get_point_interpolate(rope_position)
        var diff := global_position - point_pos
        var pos_a: Vector2 = rope.get_point(point_index)
        var pos_b: Vector2 = rope.get_point(point_index + 1)
        var new_pos_a: Vector2 = pos_a + diff
        var new_pos_b: Vector2 = pos_b + diff

        _move_point(point_index, pos_a, new_pos_a)
        _move_point(point_index + 1, pos_b, new_pos_b)
    else:
        _move_point(point_index, rope.get_point(point_index), global_position)


func _move_point(idx: int, from: Vector2, to: Vector2) -> void:
    if smoothing:
        to = from.lerp(to, get_physics_process_delta_time() * position_smoothing_speed)
    _helper.target_rope.set_point(idx, to)


func set_rope_path(value: NodePath):
    rope_path = value
    if is_inside_tree():
        _helper.target_rope = get_node(rope_path) as Rope


func set_enable(value: bool):
    enable = value
    _helper.enable = value

func get_enable() -> bool:
    return _helper.enable
