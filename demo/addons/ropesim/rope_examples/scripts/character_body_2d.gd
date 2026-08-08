extends CharacterBody2D

@export var use_arrow_keys: bool = false
@export var speed: float = 300.0


func _ready() -> void:
    # To prevent a 1-frame lag, we connect to the pre_pre event, so the movement code always runs
    # before RopeHandles, RopeAnchors and the rope simulation itself.
    # It is not necessary to do this instead of just using _physics_process() but it should
    # demonstrate how to solve the lag.
    NativeRopeServer.on_pre_pre_update.connect(_update)


func _update() -> void:
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
