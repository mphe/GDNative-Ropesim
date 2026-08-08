extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_speed: float = 500.0
@export var gravity: float = 1200.0

@onready var _rope_handle: RopeHandle = $RopeHandle


func _ready() -> void:
    var area: Area2D = $Area2D
    area.body_entered.connect(_rope_entered)

    # Reset the rope into east direction so there is less erratic movement until it reaches its resting position.
    # In an actual game this would obviously not be handled by the player code.
    var rope: Rope = $"%Rope"
    rope.reset(Vector2.RIGHT)


func _physics_process(delta: float) -> void:
    var hdir := 0
    var grounded: bool = is_on_floor()
    var move_speed := speed
    var on_rope := _rope_handle.enable

    if Input.is_key_pressed(KEY_A):
        hdir -= 1
    if Input.is_key_pressed(KEY_D):
        hdir += 1

    if grounded:
        velocity.y = 0

        if Input.is_key_pressed(KEY_SPACE):
            velocity.y -= jump_speed
            _rope_handle.enable = false

    velocity.x = hdir * move_speed
    velocity.y += gravity * delta

    move_and_slide()

    if on_rope:
        _rope_handle.use_nearest_position()


func _rope_entered(node: Node) -> void:
    # The rope area will have a collision generator which we use to get the actual rope node
    var shape_generator := node.get_node("RopeCollisionShapeGenerator") as RopeCollisionShapeGenerator
    if shape_generator:
        _rope_handle.rope_path = shape_generator.rope_path
        _rope_handle.enable = true
        _rope_handle.use_nearest_position()
