@tool
extends Area2D

@onready var indicator: Label = $indicator

func _ready() -> void:
    body_entered.connect(_body_entered)
    body_exited.connect(_body_exited)
    indicator.visible = false


func _body_entered(_body: Node2D) -> void:
    indicator.visible = true


func _body_exited(_body: Node2D) -> void:
    indicator.visible = false
