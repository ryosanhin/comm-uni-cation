extends Node

@export var _button: Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_button.grab_focus()
	_button.pressed.connect(_delete)


func _delete() -> void:
	queue_free()
