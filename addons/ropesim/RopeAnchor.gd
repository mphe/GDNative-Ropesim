tool
extends Position2D
class_name RopeAnchor

export var enable: bool = true setget set_enable, get_enable
export(NodePath) var rope_path setget set_rope_path
export(float, 0, 1) var rope_position = 1.0
export var apply_angle := false
var _helper: RopeToolHelper


func _init() -> void:
    if not _helper:
        _helper = RopeToolHelper.new(RopeToolHelper.UPDATE_HOOK_POST, self, "_on_post_update")
        add_child(_helper)


func _ready() -> void:
    set_rope_path(rope_path)
    set_enable(enable)


func _on_post_update() -> void:
    var rope: Rope = _helper.target_rope

    global_position = rope.get_point(rope.get_point_index(rope_position))
    if apply_angle:
        var a := rope.get_point(rope.get_point_index(rope_position - 0.1))
        var b := rope.get_point(rope.get_point_index(rope_position + 0.1))
        global_rotation = (b - a).angle()


func set_rope_path(value: NodePath):
    rope_path = value
    if is_inside_tree():
        _helper.target_rope = get_node(rope_path) as Rope


func set_enable(value: bool):
    enable = value
    _helper.enable = value

func get_enable() -> bool:
    return _helper.enable
