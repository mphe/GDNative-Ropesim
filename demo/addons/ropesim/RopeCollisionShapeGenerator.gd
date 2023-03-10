tool
extends Node
class_name RopeCollisionShapeGenerator

# Populates the parent with CollisionShape2Ds with a SegmentShape2D to fit the target rope.
# It can be added as child to an Area2D for example, to detect if something collides with the rope.
# It does _not_ make the rope interact with other physics objects.

export var enable: bool = true setget set_enable, get_enable  # Enable or disable.
export(NodePath) var rope_path setget set_rope_path  # Target rope path.

var _helper: RopeToolHelper
var _colliders := []  # Array[CollisionShape2D]


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


func set_rope_path(value: NodePath):
    rope_path = value
    if is_inside_tree():
        _helper.target_rope = get_node(rope_path) as Rope
        _build()


func set_enable(value: bool):
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
    var diff = num - _colliders.size()

    if diff > 0:
        for i in diff:
            var shape := CollisionShape2D.new()
            shape.shape = SegmentShape2D.new()
            get_parent().call_deferred("add_child", shape)
            _colliders.append(shape)
    elif diff < 0:
        for i in abs(diff):
            _colliders.pop_back().queue_free()


func _update_shapes() -> void:
    var points = _helper.target_rope.get_points()
    var root = _helper.target_rope.global_position

    for i in range(0, _colliders.size() - 1):
        var c: CollisionShape2D = _colliders[i]
        var seg: SegmentShape2D = c.shape
        seg.a = points[i] - root
        seg.b = points[i + 1] - root
