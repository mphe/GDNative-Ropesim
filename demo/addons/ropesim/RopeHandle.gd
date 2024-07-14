@tool
extends Marker2D
class_name RopeHandle

## Gets emitted just before applying the position.
signal on_before_update()

## Enable or disable
@export var enable: bool = true: get = get_enable, set = set_enable
## Target rope node.
@export_node_path("Rope") var rope_path: NodePath: set = set_rope_path
## Position on the rope between 0 and 1.
@export_range(0.0, 1.0) var rope_position: float = 1.0 : set = set_rope_position
## Whether to smoothly snap to RopeHandle's position instead of instantly.
@export var smoothing: bool = false
## Smoothing speed
@export var position_smoothing_speed: float = 0.5
## If false, only affect the nearest vertex on the rope. Otherwise, affect both surrounding points when applicable.
@export var precise: bool = false
## Determines how much the target point is allowed to move. A value of 0.0 sets the point's position
## but it is still fully affected by simulation and constraining.
## A value of 1.0 completely fixates the point at the handle's position and allows no further movement.
@export_range(0.0, 1.0) var strength: float = 0.0 : set = set_strength

var _helper: RopeToolHelper
var _target_idx: int = 0


func _init() -> void:
    if not _helper:
        _helper = RopeToolHelper.new(RopeToolHelper.UPDATE_HOOK_PRE, self, "_on_pre_update")
        _helper.on_rope_assigned.connect(_on_rope_assigned)
        add_child(_helper)


func _ready() -> void:
    set_rope_path(rope_path)
    set_enable(enable)


func _enter_tree() -> void:
    _update_state(null)


func _exit_tree() -> void:
    _restore_state(_helper.target_rope)


func _on_pre_update() -> void:
    on_before_update.emit()
    var rope: Rope = _helper.target_rope

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


func set_rope_path(value: NodePath) -> void:
    rope_path = value

    if is_inside_tree():
        _helper.target_rope = get_node(rope_path) as Rope


func set_enable(value: bool) -> void:
    if enable == value:
        return

    enable = value
    _helper.enable = value

    if not enable:
        _restore_state(_helper.target_rope)
    else:
        _update_state(null)


func get_enable() -> bool:
    return _helper.enable


func set_strength(value: float) -> void:
    strength = value
    _update_state_current_rope()


func set_rope_position(value: float) -> void:
    rope_position = value
    _update_state_current_rope()


func _on_rope_assigned(old: Rope) -> void:
    _update_state(old)


func _update_state_current_rope() -> void:
    _update_state(_helper.target_rope)


func _update_state(old_rope: Rope) -> void:
    if not enable:
        return

    _restore_state(old_rope)

    var rope := _helper.target_rope

    # Compute and apply new state
    if rope:
        _target_idx = rope.get_point_index(rope_position)
        # TODO: Maybe set this value in _on_pre_update() so if it gets overwritten by another
        # handle, it will be automatically restored when the other handle targets a different position again.
        rope.set_point_simulation_weight(_target_idx, 1.0 - clampf(strength, 0.0, 1.0))


func _restore_state(rope: Rope) -> void:
    if rope:
        rope.set_point_simulation_weight(_target_idx, 1.0)
