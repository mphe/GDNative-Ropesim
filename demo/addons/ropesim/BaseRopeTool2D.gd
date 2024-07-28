extends Marker2D
class_name BaseRopeTool2D

## Base class for tools like [RopeHandle] and [RopeAnchor] which work on a specific position on a
## specific rope.

## Fake property to trigger a refresh in editor.
@export var force_update: bool: set = _set_force_update

## Enable or disable processing.
@export var enable: bool = true : set = set_enable

## Target rope node.
@export_node_path("Rope") var rope_path: NodePath : set = set_rope_path

## Position on the rope between 0 and 1.
@export_range(0.0, 1.0) var rope_position: float = 1.0 : set = set_rope_position

## If false, only consider the nearest vertex on the rope. Otherwise, interpolate the position between two relevant points when applicable.
@export var precise: bool = false


var _helper: RopeToolHelper


func _init(rope_tool_helper: RopeToolHelper) -> void:
    _helper = rope_tool_helper
    add_child(_helper)


func _ready() -> void:
    set_rope_path(rope_path)
    set_enable(enable)


## Determine the nearest position on the rope to this node and use it as target position.
func use_nearest_position() -> void:
    use_nearest_position_to_point(global_position)


## Determine the nearest position on the rope to the given point and use it as target position.
func use_nearest_position_to_point(point: Vector2) -> void:
    var rope := _helper.target_rope
    if rope:
        # TODO: Determine precise percentage, not just nearest index
        var idx := rope.get_nearest_point_index(point)
        var perc := rope.get_point_perc(idx)
        rope_position = perc


func set_rope_path(value: NodePath) -> void:
    rope_path = value

    if is_inside_tree():
        _helper.set_target_rope_path(rope_path, self)


func set_enable(value: bool) -> void:
    enable = value
    _helper.enable = value


func set_rope_position(value: float) -> void:
    if value == rope_position:
        return
    rope_position = value


func _set_force_update(_val: bool) -> void:
    if _helper.target_rope:
        _update()


## Should be overridden
func _update() -> void:
    pass
