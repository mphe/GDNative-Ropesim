extends Node2D

const MAX_SQR_DISTANCE = 300 * 300

@onready var main_rope: Rope = %main_rope
@onready var fixation: RopeHandle = %fixation
@onready var split_rope_left: Rope = %split_rope_left
@onready var split_rope_left_handle: RopeHandle = %split_rope_left_handle
@onready var split_rope_right_handle: RopeHandle = %split_rope_right_handle
@onready var split_rope_right: Rope = %split_rope_right

func _ready() -> void:
    split_rope_left.visible = false
    split_rope_right.visible = false

func _physics_process(_delta: float) -> void:
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        fixation.global_position = get_global_mouse_position()

    if fixation.enable and main_rope.global_position.distance_squared_to(fixation.global_position) > MAX_SQR_DISTANCE:
        fixation.enable = false
        main_rope.pause = true
        main_rope.render_line = false
        split_rope_left.visible = true
        split_rope_right.visible = true
        split_rope_left_handle.enable = false
        split_rope_right_handle.enable = false
