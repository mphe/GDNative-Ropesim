tool
extends EditorPlugin

const MENU_INDEX_UPDATE_IN_EDITOR = 0

var _menu_toolbox: HBoxContainer
var _menu_popup: PopupMenu

var _NativeRopeServer: Node
var _Rope
var _RopeAnchor
var _RopeHandle
var _RopeRendererLine2D

func _enter_tree() -> void:
    add_autoload_singleton("NativeRopeServer", "res://addons/ropesim/NativeRopeServer.gdns")

    # It takes a frame until the autoload exists in the tree.
    # We need to wait because subsequent code requires the NativeRopeServer autoload to exist.
    # See also here: https://github.com/godotengine/godot/issues/30064
    yield(get_tree(), "idle_frame")

    # _NativeRopeServer = Engine.get_singleton("NativeRopeServer")  # Doesn't work for some reason
    _NativeRopeServer = get_node("/root/NativeRopeServer")

    # We can't reference class names directly because of dependencies issues when loading the Plugin.
    # plugin.gd -> Rope.gd -> NativeRopeServer -> NativeRopeServer hasn't been loaded yet
    # -> Rope.gd Error -> plugin.gd Error
    _Rope = load("res://addons/ropesim/Rope.gd")
    _RopeAnchor = load("res://addons/ropesim/RopeAnchor.gd")
    _RopeHandle = load("res://addons/ropesim/RopeHandle.gd")
    _RopeRendererLine2D = load("res://addons/ropesim/RopeRendererLine2D.gd")

    _build_gui()


func _exit_tree() -> void:
    remove_autoload_singleton("NativeRopeServer")
    _free_gui()


func handles(object: Object) -> bool:
    if _menu_toolbox:
        _menu_toolbox.hide()
    return object is _Rope \
        or object is _RopeAnchor \
        or object is _RopeHandle \
        or object is _RopeRendererLine2D


func edit(object: Object) -> void:
    _menu_toolbox.show()


func make_visible(visible: bool) -> void:
    pass


func _build_gui() -> void:
    _menu_toolbox = HBoxContainer.new()
    _menu_toolbox.hide()
    add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _menu_toolbox)

    var menu_button = MenuButton.new()
    menu_button.text = "Ropesim"
    _menu_toolbox.add_child(menu_button)
    _menu_popup = menu_button.get_popup()
    _menu_popup.add_check_item("Preview in Editor")
    _menu_popup.set_item_checked(MENU_INDEX_UPDATE_IN_EDITOR, _NativeRopeServer.update_in_editor)
    _menu_popup.connect("id_pressed", self, "_menu_item_clicked")


func _menu_item_clicked(idx: int) -> void:
    match idx:
        MENU_INDEX_UPDATE_IN_EDITOR:
            var value = not _menu_popup.is_item_checked(idx)
            _menu_popup.set_item_checked(MENU_INDEX_UPDATE_IN_EDITOR, value)
            _NativeRopeServer.update_in_editor = value


func _free_gui() -> void:
    remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _menu_toolbox)
    _menu_toolbox.queue_free()
    _menu_toolbox = null
    _menu_popup = null
