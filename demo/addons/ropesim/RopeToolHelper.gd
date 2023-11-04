extends Node
class_name RopeToolHelper

# This node should be used programmatically as helper in other rope tools.
# It contains boilerplate for registering/unregistering to/from NativeRopeServer when needed.

const UPDATE_HOOK_POST = "on_post_update"
const UPDATE_HOOK_PRE = "on_pre_update"

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
        NativeRopeServer.disconnect(_update_hook, Callable(self, "_on_update"))


func _is_registered() -> bool:
    return NativeRopeServer.is_connected(_update_hook, Callable(self, "_on_update"))


func _on_update() -> void:
    if not target_rope.pause:
        _target.call(_target_method)


# Start or stop the process depending on internal variables.
func start_stop_process() -> void:
    # NOTE: It sounds smart to disable this helper if the rope is paused, but maybe there are exceptions.
    if enable and is_inside_tree() and target_rope and not target_rope.pause:
        if not _is_registered():
            NativeRopeServer.connect(_update_hook, Callable(self, "_on_update"))
    else:
        _unregister_server()


func set_enable(value: bool) -> void:
    enable = value
    start_stop_process()


func set_target_rope(value: Rope) -> void:
    if value == target_rope:
        return

    if target_rope and is_instance_valid(target_rope):
        target_rope.disconnect("on_registered", Callable(self, "start_stop_process"))
        target_rope.disconnect("on_unregistered", Callable(self, "start_stop_process"))

    target_rope = value

    if target_rope and is_instance_valid(target_rope):
        target_rope.connect("on_registered", Callable(self, "start_stop_process"))  # warning-ignore: return_value_discarded
        target_rope.connect("on_unregistered", Callable(self, "start_stop_process"))  # warning-ignore: return_value_discarded

    start_stop_process()
