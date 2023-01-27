tool
extends Position2D
class_name RopeHandle

export var preview_in_editor: bool = false setget _set_preview
export var enable: bool = true setget _set_enable
export(NodePath) var rope_path setget _set_rope_path
export(float, 0, 1) var rope_position = 1.0
export var smoothing: bool = false
export var smoothing_speed: float = 0.5

onready var _rope: Rope


func _ready() -> void:
    process_priority = -1
    _set_rope_path(rope_path)


func _physics_process(_delta: float) -> void:
    var point_index: int = _rope.get_point_index(rope_position)
    var new_pos: Vector2
    if smoothing:
        new_pos = _rope.get_point(point_index).linear_interpolate(global_position, smoothing_speed)
    else:
        new_pos = global_position
    _rope.set_point(point_index, new_pos)


func _set_rope_path(value: NodePath):
    rope_path = value
    if is_inside_tree():
        _rope = get_node(rope_path) as Rope
        _set_enable(enable)


func _set_preview(value: bool):
    preview_in_editor = value
    if Engine.editor_hint:
        set_physics_process(preview_in_editor)


func _set_enable(value: bool):
    enable = value
    set_physics_process(enable and _rope != null)
