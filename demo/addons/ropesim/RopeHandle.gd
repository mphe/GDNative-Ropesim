@tool
extends BaseRopeTool2D
class_name RopeHandle

## Can be used to control, animate or fixate points on a target rope.

## Gets emitted just before applying the position. This happens always during _physics_process().
signal on_before_update()


## Whether to smoothly snap to RopeHandle's position instead of instantly.
@export var smoothing: bool = false

## Smoothing speed
@export var position_smoothing_speed: float = 0.5

## Determines how much the target point is allowed to move. A value of 0.0 sets the point's position
## but it is still fully affected by simulation and constraining.
## A value of 1.0 completely fixates the point at the handle's position and allows no further movement.
@export_range(0.0, 1.0) var strength: float = 0.0 : set = set_strength

var _target_idx: int = 0


func _init() -> void:
    super._init(RopeToolHelper.new(RopeToolHelper.UPDATE_HOOK_PRE, self, "_on_pre_update"))
    _helper.on_rope_assigned.connect(_on_rope_assigned)


func _enter_tree() -> void:
    _update_state(null)


func _exit_tree() -> void:
    _restore_state(_helper.target_rope)


func _on_pre_update() -> void:
    on_before_update.emit()
    _update()


func _update() -> void:
    var rope: Rope = _helper.target_rope

    # The point weight is set here instead of _update_state() to ensure that handles do not
    # overwrite each other's strength values if they coincidentally target the same point index.
    rope.set_point_simulation_weight(_target_idx, 1.0 - strength)

    # Only use this method if this is not the last point.
    if precise and _target_idx < rope.get_num_points() - 1:
        # TODO: Consider creating a corresponding function in Rope.gd for universal access, e.g. set_point_interpolated().
        var point_pos: Vector2 = rope.get_point_interpolate(rope_position)
        var diff := global_position - point_pos
        var pos_a: Vector2 = rope.get_point(_target_idx)
        var pos_b: Vector2 = rope.get_point(_target_idx + 1)
        var new_pos_a: Vector2 = pos_a + diff
        var new_pos_b: Vector2 = pos_b + diff

        _move_point(_target_idx, pos_a, new_pos_a)
        _move_point(_target_idx  + 1, pos_b, new_pos_b)
    else:
        _move_point(_target_idx, rope.get_point(_target_idx), global_position)


func _move_point(idx: int, from: Vector2, to: Vector2) -> void:
    if smoothing:
        to = from.lerp(to, get_physics_process_delta_time() * position_smoothing_speed)
    _helper.target_rope.set_point(idx, to)


func set_enable(value: bool) -> void:
    if enable == value:
        return

    super.set_enable(value)

    if enable:
        _update_state(null)
    else:
        _restore_state(_helper.target_rope)


func set_strength(value: float) -> void:
    strength = clampf(value, 0.0, 1.0)
    _update_state_current_rope()


func set_rope_position(value: float) -> void:
    super.set_rope_position(value)
    _update_state_current_rope()


func _on_rope_assigned(old: Rope) -> void:
    _update_state(old)

    if old:
        old.on_point_count_changed.disconnect(_on_point_count_changed)

    if _helper.target_rope:
        _helper.target_rope.on_point_count_changed.connect(_on_point_count_changed)


func _on_point_count_changed() -> void:
    _update_state_current_rope()


func _update_state_current_rope() -> void:
    _update_state(_helper.target_rope)


func _update_state(old_rope: Rope) -> void:
    if not enable:
        return

    _restore_state(old_rope)

    var rope := _helper.target_rope

    if rope:
        _target_idx = rope.get_point_index(rope_position)


func _restore_state(rope: Rope) -> void:
    if rope:
        rope.set_point_simulation_weight(_target_idx, 1.0)
