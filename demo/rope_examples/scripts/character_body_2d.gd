extends CharacterBody2D

@export var use_arrow_keys: bool = false
@export var speed: float = 300.0


func _physics_process(_delta: float) -> void:
    var wishdir := Vector2()

    if use_arrow_keys:
        if Input.is_key_pressed(KEY_LEFT):
            wishdir.x -= 1
        if Input.is_key_pressed(KEY_RIGHT):
            wishdir.x += 1
        if Input.is_key_pressed(KEY_UP):
            wishdir.y -= 1
        if Input.is_key_pressed(KEY_DOWN):
            wishdir.y += 1
    else:
        if Input.is_key_pressed(KEY_A):
            wishdir.x -= 1
        if Input.is_key_pressed(KEY_D):
            wishdir.x += 1
        if Input.is_key_pressed(KEY_W):
            wishdir.y -= 1
        if Input.is_key_pressed(KEY_S):
            wishdir.y += 1

    velocity = wishdir.normalized() * speed
    move_and_slide()
