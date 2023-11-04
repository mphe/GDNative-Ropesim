@tool
extends Marker2D
class_name RopeAnchor

# Gets emitted just after applying the position.
signal on_after_update()

@export var force_update: bool: set = _set_force_update
@export var enable: bool = true: get = get_enable, set = set_enable  # Enable or disable.
@export var rope_path: NodePath: set = set_rope_path
@export var rope_position = 1.0  # Position on the rope between 0 and 1. # (float, 0, 1)
@export var apply_angle := false  # Also apply rotation according to the rope curvature.
## If false, only consider the nearest vertex on the rope. Otherwise, interpolate the position between two relevant points when applicable.
@export var precise: bool = false
var _helper: RopeToolHelper


func _init() -> void:
    if not _helper:
        _helper = RopeToolHelper.new(RopeToolHelper.UPDATE_HOOK_POST, self, "_on_post_update")
        add_child(_helper)


func _ready() -> void:
    set_rope_path(rope_path)
    set_enable(enable)


func _on_post_update() -> void:
    _update()
    emit_signal("on_after_update")


func set_rope_path(value: NodePath):
    rope_path = value
    if is_inside_tree():
        _helper.target_rope = get_node(rope_path) as Rope


func set_enable(value: bool):
    enable = value
    _helper.enable = value


func get_enable() -> bool:
    return _helper.enable


func _update() -> void:
    var rope: Rope = _helper.target_rope

    if precise:
        global_position = rope.get_point_interpolate(rope_position)
    else:
        global_position = rope.get_point(rope.get_point_index(rope_position))

    if apply_angle:
        var a := rope.get_point(rope.get_point_index(rope_position - 0.1))
        var b := rope.get_point(rope.get_point_index(rope_position + 0.1))
        global_rotation = (b - a).angle()


func _set_force_update(_val: bool) -> void:
    if Engine.is_editor_hint() and _helper.target_rope:
        _update()
