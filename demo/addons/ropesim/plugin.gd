@tool
extends EditorPlugin

const MENU_INDEX_UPDATE_IN_EDITOR = 0

var _menu_toolbox: HBoxContainer
var _menu_popup: PopupMenu

func _enter_tree() -> void:
    _build_gui()


func _exit_tree() -> void:
    _free_gui()


func _handles(object: Object) -> bool:
    if _menu_toolbox:
        _menu_toolbox.hide()

    return (
        object is Rope or
        object is RopeAnchor or
        object is RopeHandle or
        object is RopeCollisionShapeGenerator or
        object is RopeRendererLine2D
    )


func _edit(_object: Object) -> void:
    _menu_toolbox.show()


func _build_gui() -> void:
    _menu_toolbox = HBoxContainer.new()
    _menu_toolbox.hide()
    add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _menu_toolbox)

    var menu_button = MenuButton.new()
    menu_button.text = "Ropesim"
    _menu_toolbox.add_child(menu_button)
    _menu_popup = menu_button.get_popup()
    _menu_popup.add_check_item("Preview in Editor")
    _menu_popup.set_item_checked(MENU_INDEX_UPDATE_IN_EDITOR, NativeRopeServer.update_in_editor)
    _menu_popup.connect("id_pressed", self._menu_item_clicked)


func _menu_item_clicked(idx: int) -> void:
    match idx:
        MENU_INDEX_UPDATE_IN_EDITOR:
            var value = not _menu_popup.is_item_checked(idx)
            _menu_popup.set_item_checked(MENU_INDEX_UPDATE_IN_EDITOR, value)
            NativeRopeServer.update_in_editor = value


func _free_gui() -> void:
    remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _menu_toolbox)
    _menu_toolbox.queue_free()
    _menu_toolbox = null
    _menu_popup = null
