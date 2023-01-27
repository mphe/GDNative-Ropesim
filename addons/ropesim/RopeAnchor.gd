tool
extends Position2D
class_name RopeAnchor

export var preview_in_editor: bool = false setget _set_preview
export var enable: bool = true setget _set_enable
export(NodePath) var rope_path setget _set_rope_path
export(float, 0, 1) var rope_position = 1.0
export var apply_angle := false
var _rope: Rope


func _ready() -> void:
    process_priority = 5000
    _set_rope_path(rope_path)
    _set_enable(enable)


func _physics_process(_delta: float) -> void:
    global_position = _rope.get_point(_rope.get_point_index(rope_position))
    if apply_angle:
        var a := _rope.get_point(_rope.get_point_index(rope_position - 0.1))
        var b := _rope.get_point(_rope.get_point_index(rope_position + 0.1))
        global_rotation = (b - a).angle()


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
    set_physics_process(enable and _rope != null and not Engine.editor_hint)
