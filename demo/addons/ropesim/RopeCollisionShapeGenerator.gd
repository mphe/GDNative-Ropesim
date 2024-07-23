@tool
extends Node
class_name RopeCollisionShapeGenerator

## Populates the parent with CollisionShape2Ds with a SegmentShape2D to fit the target rope.
## It can be added as child to an Area2D for example, to detect if something collides with the rope.
## It does _not_ make the rope interact with other physics objects.

## Enable or disable.
@export var enable: bool = true: get = get_enable, set = set_enable
## Target rope node.
@export_node_path("Rope") var rope_path: NodePath: set = set_rope_path

var _helper: RopeToolHelper
var _colliders: Array[CollisionShape2D] = []


func _init() -> void:
    if not _helper:
        _helper = RopeToolHelper.new(RopeToolHelper.UPDATE_HOOK_POST, self, "_on_post_update")
        add_child(_helper)


func _ready() -> void:
    if not get_parent() is CollisionObject2D:
        push_warning("Parent is not a CollisionObject2D")
    set_rope_path(rope_path)
    set_enable(enable)


func _on_post_update() -> void:
    if _needs_rebuild():
        _build()
    _update_shapes()


func set_rope_path(value: NodePath) -> void:
    rope_path = value
    if is_inside_tree():
        _helper.target_rope = get_node(rope_path) as Rope
        _build()


func set_enable(value: bool) -> void:
    enable = value
    _helper.enable = value


func get_enable() -> bool:
    return _helper.enable


func _needs_rebuild() -> bool:
    var rope: Rope = _helper.target_rope
    return rope and rope.num_segments != _colliders.size()


func _build() -> void:
    var rope: Rope = _helper.target_rope

    if rope:
        _enable_shapes(rope.num_segments)
    else:
        _enable_shapes(0)


func _enable_shapes(num: int) -> void:
    var diff := num - _colliders.size()

    if diff > 0:
        for i in diff:
            var shape := CollisionShape2D.new()
            shape.shape = SegmentShape2D.new()
            _colliders.append(shape)
            get_parent().call_deferred("add_child", shape)
    elif diff < 0:
        for i in absi(diff):
            @warning_ignore("unsafe_method_access")
            _colliders.pop_back().queue_free()


func _update_shapes() -> void:
    var points := _helper.target_rope.get_points()

    for i in _colliders.size():
        var shape: CollisionShape2D = _colliders[i]
        shape.global_transform = Transform2D(0, Vector2.ZERO)  # set_as_top_level() is buggy with collision shapes
        var seg: SegmentShape2D = shape.shape
        seg.a = points[i]
        seg.b = points[i + 1]
