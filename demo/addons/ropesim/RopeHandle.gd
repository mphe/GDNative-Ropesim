tool
extends Position2D
class_name RopeHandle

export var enable: bool = true setget set_enable, get_enable  # Enable or disable
export(NodePath) var rope_path setget set_rope_path  # Target rope path
export(float, 0, 1) var rope_position = 1.0  # Position on the rope between 0 and 1.
export var smoothing: bool = false  # Whether to smoothly snap to RopeHandle's position instead of instantly.
export var smoothing_speed: float = 0.5  # Smoothing speed
var _helper: RopeToolHelper


func _init() -> void:
    if not _helper:
        _helper = RopeToolHelper.new(RopeToolHelper.UPDATE_HOOK_PRE, self, "_on_pre_update")
        add_child(_helper)


func _ready() -> void:
    set_rope_path(rope_path)
    set_enable(enable)


func _on_pre_update() -> void:
    var rope: Rope = _helper.target_rope
    var point_index: int = rope.get_point_index(rope_position)
    var new_pos: Vector2
    if smoothing:
        new_pos = rope.get_point(point_index).linear_interpolate(global_position, get_physics_process_delta_time() * smoothing_speed)
    else:
        new_pos = global_position
    rope.set_point(point_index, new_pos)


func set_rope_path(value: NodePath):
    rope_path = value
    if is_inside_tree():
        _helper.target_rope = get_node(rope_path) as Rope


func set_enable(value: bool):
    enable = value
    _helper.enable = value

func get_enable() -> bool:
    return _helper.enable
