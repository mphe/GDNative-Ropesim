extends Node
class_name RopeToolHelper

# This node should be used programmatically as helper in other rope tools.
# It contains boilerplate for registering/unregistering to/from NativeRopeServer when needed.

const UPDATE_HOOK_POST = "on_post_update"
const UPDATE_HOOK_PRE = "on_pre_update"

export var enable: bool = true setget set_enable
var target_rope: Rope setget set_target_rope

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
        NativeRopeServer.disconnect(_update_hook, self, "_on_update")


func _is_registered() -> bool:
    return NativeRopeServer.is_connected(_update_hook, self, "_on_update")


func _on_update() -> void:
    if not target_rope.pause:
        _target.call(_target_method)


# Start or stop the process depending on internal variables.
# additional_enable_requirement can be used to pass an expression that acts as an additional
# requirement for enabling processing.
func start_stop_process() -> void:
    if enable and is_inside_tree() and target_rope:
        if not _is_registered():
            NativeRopeServer.connect(_update_hook, self, "_on_update")  # warning-ignore: return_value_discarded
    else:
        _unregister_server()


func set_enable(value: bool) -> void:
    enable = value
    start_stop_process()


func set_target_rope(value: Rope) -> void:
    target_rope = value
    start_stop_process()
