@tool
extends BaseRopeTool2D
class_name RopeAnchor

## Can be used to attach nodes at certain positions on a target rope.

## Gets emitted just after applying the position. This happens always during _physics_process().
signal on_after_update()

## Also apply rotation according to the rope curvature.
@export var apply_angle := false

var _last_pos: Vector2


func _init() -> void:
    super._init(RopeToolHelper.new(RopeToolHelper.UPDATE_HOOK_POST, self, "_on_post_update"))


func _on_post_update() -> void:
    _update()
    on_after_update.emit()


func set_rope_path(value: NodePath) -> void:
    rope_path = value

    if is_inside_tree():
        _helper.set_target_rope_path(rope_path, self)


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
