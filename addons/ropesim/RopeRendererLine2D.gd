tool
extends Line2D
class_name RopeRendererLine2D

export var force_update: bool setget _force_update
export var target_rope_path: NodePath = ".." setget _set_rope_path
export var keep_rope_position: bool = true setget _set_keep_pos
export var auto_update: bool = true setget _set_auto_update
var _target: Rope


func _ready() -> void:
    _set_rope_path(target_rope_path)
    _set_auto_update(auto_update)
    refresh()


func _physics_process(_delta: float) -> void:
    refresh()


func refresh() -> void:
    if _target and _target.get_num_points() > 0 and visible and not _target.pause:
        var transform: Transform2D
        if keep_rope_position:
            if Engine.editor_hint:
                transform = Transform2D(0, -global_position -_target.get_point(0) + _target.global_position)
            else:
                transform = Transform2D(0, -global_position)
        else:
            transform = Transform2D(0, -_target.get_point(0))
        transform = transform.scaled(scale)
        points = transform.xform(_target.get_points())
        global_rotation = 0


func _set_rope_path(value: NodePath):
    target_rope_path = value
    if is_inside_tree():
        _target = get_node(target_rope_path) as Rope
        refresh()


func _force_update(_value: bool):
    refresh()


func _set_keep_pos(value: bool):
    keep_rope_position = value
    refresh()


func _set_auto_update(value: bool):
    auto_update = value
    set_physics_process(not Engine.editor_hint and auto_update)
