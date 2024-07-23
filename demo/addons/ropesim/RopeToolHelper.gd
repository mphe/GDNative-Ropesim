extends Node
class_name RopeToolHelper

## This node should be used programmatically as helper in other rope tools.
## It contains boilerplate for registering/unregistering to/from NativeRopeServer when needed.

const UPDATE_HOOK_POST = "on_post_update"
const UPDATE_HOOK_PRE = "on_pre_update"

## Emitted when the assigned rope has been changed, i.e. to a new rope or null.
signal on_rope_assigned(old: Rope)

@export var enable: bool = true: set = set_enable
var target_rope: Rope: set = set_target_rope

var _update_hook: String
var _target_method: String
var _target: Object


func _init(update_hook: String, target: Object, target_method: String) -> void:
    _update_hook = update_hook
    _target = target
    _target_method = target_method


func _enter_tree() -> void:
    start_stop_process()


func _exit_tree() -> void:
    _unregister_server()


func _unregister_server() -> void:
    if _is_registered():
        NativeRopeServer.disconnect(_update_hook, _on_update)


func _is_registered() -> bool:
    return NativeRopeServer.is_connected(_update_hook, _on_update)


func _on_update() -> void:
    if not target_rope.pause:
        _target.call(_target_method)


# Start or stop the process depending on internal variables.
func start_stop_process() -> void:
    # NOTE: It sounds smart to disable this helper if the rope is paused, but maybe there are exceptions.
    if enable and is_inside_tree() and target_rope and not target_rope.pause:
        if not _is_registered():
            NativeRopeServer.connect(_update_hook, _on_update)
    else:
        _unregister_server()


func set_enable(value: bool) -> void:
    enable = value
    start_stop_process()


func set_target_rope(value: Rope) -> void:
    if value == target_rope:
        return

    if target_rope and is_instance_valid(target_rope):
        target_rope.on_registered.disconnect(start_stop_process)
        target_rope.on_unregistered.disconnect(start_stop_process)

    var old := target_rope
    target_rope = value

    if target_rope and is_instance_valid(target_rope):
        target_rope.on_registered.connect(start_stop_process)
        target_rope.on_unregistered.connect(start_stop_process)

    start_stop_process()
    on_rope_assigned.emit(old)


## Set the target rope using a NodePath. Allows empty paths and treats them as null.
## If [param path_relative_node] is given, the path will be resolved relative to that node.
func set_target_rope_path(rope_path: NodePath, path_relative_node: Node = null) -> void:
    if not is_inside_tree():
        push_warning("RopeToolHelper: Trying to assign rope but not added to tree")
        return

    var node: Rope = null

    if rope_path:
        if path_relative_node:
            node = path_relative_node.get_node(rope_path) as Rope
        else:
            node = get_node(rope_path) as Rope

    set_target_rope(node)
