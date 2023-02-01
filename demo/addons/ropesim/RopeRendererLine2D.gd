tool
extends Line2D
class_name RopeRendererLine2D

const UPDATE_HOOK = "on_post_update"
const HOOK_FUNC = "refresh"

export var force_update: bool setget _force_update  # Can be used in Editor to force regenerating.
export var target_rope_path: NodePath = ".." setget set_rope_path  # Target rope path
export var keep_rope_position: bool = true setget _set_keep_pos  # Render at the rope's position instead of RopeRendererLine2D's position.
export var auto_update: bool = true setget set_auto_update, get_auto_update  # Automatically update
var _helper: RopeToolHelper


func _init() -> void:
    if not _helper:
        _helper = RopeToolHelper.new(RopeToolHelper.UPDATE_HOOK_POST, self, "refresh")
        add_child(_helper)


func _ready() -> void:
    set_rope_path(target_rope_path)
    set_auto_update(auto_update)
    refresh()


func refresh() -> void:
    var target: Rope = _helper.target_rope

    if target and target.get_num_points() > 0 and visible:
        var transform: Transform2D
        if keep_rope_position:
            if Engine.editor_hint:
                transform = Transform2D(0, -global_position - target.get_point(0) + target.global_position)
            else:
                transform = Transform2D(0, -global_position)
        else:
            transform = Transform2D(0, -target.get_point(0))
        transform = transform.scaled(scale)
        points = transform.xform(target.get_points())
        global_rotation = 0


func set_rope_path(value: NodePath):
    target_rope_path = value
    if is_inside_tree():
        _helper.target_rope = get_node(target_rope_path) as Rope
        refresh()


func _force_update(_value: bool):
    refresh()


func _set_keep_pos(value: bool):
    keep_rope_position = value
    refresh()


func set_auto_update(value: bool):
    auto_update = value
    _helper.enable = value

func get_auto_update() -> bool:
    return _helper.enable
