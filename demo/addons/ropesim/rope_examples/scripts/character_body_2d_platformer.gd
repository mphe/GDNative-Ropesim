extends CharacterBody2D

@export var climp_speed: float = 1.0
@export var rope_speed: float = 50.0
@export var speed: float = 300.0
@export var jump_speed: float = 500.0
@export var gravity: float = 1200.0

var _rope_interaction: RopeInteraction


func _ready() -> void:
    _rope_interaction = $RopeInteraction

    var area: Area2D = $Area2D
    area.area_entered.connect(_rope_area_entered)


func _physics_process(delta: float) -> void:
    var hdir := 0
    var on_rope := _rope_interaction.enable
    var grounded: bool = is_on_floor() or on_rope
    var move_speed := speed

    if Input.is_key_pressed(KEY_A):
        hdir -= 1
    if Input.is_key_pressed(KEY_D):
        hdir += 1

    if on_rope:
        var vdir := 0
        if Input.is_key_pressed(KEY_W):
            vdir -= 1
        if Input.is_key_pressed(KEY_S):
            vdir += 1

        _rope_interaction.rope_position = clamp(_rope_interaction.rope_position + vdir * climp_speed * delta, 0.0, 1.0)
        _rope_interaction.force_snap_to_rope()
        move_speed = rope_speed

    if grounded:
        velocity.y = 0

        if Input.is_key_pressed(KEY_SPACE):
            velocity += _rope_interaction.get_anchor().get_velocity()
            velocity.y -= jump_speed
            _rope_interaction.enable = false

    velocity.x = hdir * move_speed
    velocity.y += gravity * delta

    move_and_slide()


func _rope_area_entered(area: Area2D) -> void:
    # The rope area will have a collision generator which we use to get the actual rope node
    var shape_generator :=  area.get_node("RopeCollisionShapeGenerator") as RopeCollisionShapeGenerator
    var rope := shape_generator.get_node(shape_generator.rope_path) as Rope
    _rope_interaction.rope = rope
    _rope_interaction.enable = true
    _rope_interaction.use_nearest_position()
    _rope_interaction.force_snap_to_rope()
