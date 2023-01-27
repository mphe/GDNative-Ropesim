tool
extends MeshInstance2D
class_name RopeRenderer

export var preview_in_editor: bool = false setget _set_preview
export var start_angle := Vector2.UP
export var auto_update: bool = true setget _set_auto_update
export var target_rope_path: NodePath = ".." setget _set_rope_path

var _target: Rope
var _verts := PoolVector2Array()
var _uvs := PoolVector2Array()
var _mesh_arr := []  # Holds verts and uvs for ArrayMesh


func _enter_tree() -> void:
    _mesh_arr.resize(Mesh.ARRAY_MAX)
    mesh = ArrayMesh.new()


func _ready() -> void:
    _set_rope_path(target_rope_path)
    _set_auto_update(auto_update)
    refresh()


func _process(_delta: float) -> void:
    refresh()


func refresh() -> void:
    global_rotation = 0

    if mesh.get_surface_count() > 0:
        mesh.surface_remove(0)

    if not _target or not texture or not _mesh_arr:
        return

    var num_points := _target.get_num_points()
    if num_points <= 0:
        return

    if _verts.size() != num_points * 2:
        print("reallocate")
        _verts.resize(num_points * 2)
        _uvs.resize(_verts.size())

    print("refresh")
    _build_geo()

    # Assign arrays to mesh array.
    _mesh_arr[Mesh.ARRAY_VERTEX] = _verts
    _mesh_arr[Mesh.ARRAY_TEX_UV] = _uvs
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, _mesh_arr)


func _set_rope_path(value: NodePath):
    target_rope_path = value
    if not is_inside_tree():
        return
    _target = get_node(target_rope_path) as Rope
    refresh()


func _set_auto_update(value: bool):
    auto_update = value
    set_process((not Engine.editor_hint and auto_update) or (Engine.editor_hint and preview_in_editor))


func _set_preview(value: bool):
    preview_in_editor = value
    _set_auto_update(auto_update)


func _build_geo() -> void:
    var halfwidth := texture.get_size().y / 2.0
    var uv_segment := 1.0 / _target.num_segments
    var startp := _target.get_point(0)
    var lastp: Vector2 = start_angle

    for i in _target.get_num_points():
        var p := _target.get_point(i) - startp
        var dir := (p - lastp).normalized()
        dir = Vector2(-dir.y, dir.x)
        lastp = p
        var index = i * 2

        _verts[index]     = p - dir * halfwidth
        _verts[index + 1] = p + dir * halfwidth
        _uvs[index]       = Vector2(i * uv_segment, 0)
        _uvs[index + 1]   = Vector2(i * uv_segment, 1)


# func _draw() -> void:
#     if not _target or not texture:
#         return
#
#     var num_points = _target.get_num_points()
#     if num_points <= 0:
#         return
#
#     var halfwidth := texture.get_size().y / 2.0
#     var uv_segment := 1.0 / _target.num_segments
#
#     var points := PoolVector2Array()
#     var uvs := PoolVector2Array()
#     var colors := PoolColorArray()
#     points.resize(num_points * 2)
#     uvs.resize(points.size())
#     colors.resize(points.size())
#     var startp := _target.get_point(0)
#     var lastp: Vector2 = start_angle
#
#     for i in num_points:
#         var second_i = points.size() - 1 - i
#         var p := _target.get_point(i) - startp
#         var dir := (p - lastp).normalized()
#         dir = Vector2(-dir.y, dir.x)
#         lastp = p
#
#         points[i]        = p - dir * halfwidth
#         points[second_i] = p + dir * halfwidth
#         uvs[i]           = Vector2(i * uv_segment, 0)
#         uvs[second_i]    = Vector2(i * uv_segment, 1)
#         colors[i] = Color.white
#         colors[second_i] = Color.white
#
#     draw_polygon(points, colors, uvs, texture)
