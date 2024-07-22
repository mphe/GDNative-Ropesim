@tool
extends Label


func _enter_tree() -> void:
    NativeRopeServer.on_post_update.connect(_on_post_update)


func _on_post_update() -> void:
    text = "%s Ropes\n%.2f ms" % [ NativeRopeServer.get_num_ropes(), NativeRopeServer.get_computation_time() ]
