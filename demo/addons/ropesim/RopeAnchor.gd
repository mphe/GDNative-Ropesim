@tool
extends Marker2D
class_name RopeAnchor

## Can be used to attach nodes at certain positions on a target rope.

## Gets emitted just after applying the position. This happens always during _physics_process().
signal on_after_update()

@export var force_update: bool: set = _set_force_update
## Enable or disable.
@export var enable: bool = true: get = get_enable, set = set_enable
## Target rope node.
@export_node_path("Rope") var rope_path: NodePath: set = set_rope_path
## Position on the rope between 0 and 1.
@export_range(0.0, 1.0) var rope_position: float = 1.0
## Also apply rotation according to the rope curvature.
@export var apply_angle := false
## If false, only consider the nearest vertex on the rope. Otherwise, interpolate the position between two relevant points when applicable.
@export var precise: bool = false

var _helper: RopeToolHelper
var _last_pos: Vector2


func _init() -> void:
    if not _helper:
        _helper = RopeToolHelper.new(RopeToolHelper.UPDATE_HOOK_POST, self, "_on_post_update")
        add_child(_helper)


func _ready() -> void:
    set_rope_path(rope_path)
    set_enable(enable)


func _on_post_update() -> void:
    _update()
    on_after_update.emit()


func set_rope_path(value: NodePath) -> void:
    rope_path = value

    if is_inside_tree():
        _helper.set_target_rope_path(rope_path, self)


func set_enable(value: bool) -> void:
    enable = value
    _helper.enable = value


func get_enable() -> bool:
    return _helper.enable


## Returns the difference between the last and current position.
func get_velocity() -> Vector2:
    return global_position - _last_pos


func _update() -> void:
    var rope: Rope = _helper.target_rope

    _last_pos = global_position

    if precise:
        global_position = rope.get_point_interpolate(rope_position)
    else:
        global_position = rope.get_point(rope.get_point_index(rope_position))

    if apply_angle:
        var a := rope.get_point(rope.get_point_index(rope_position - 0.1))
        var b := rope.get_point(rope.get_point_index(rope_position + 0.1))
        global_rotation = (b - a).angle()


func _set_force_update(_val: bool) -> void:
    if _helper.target_rope:
        _update()
