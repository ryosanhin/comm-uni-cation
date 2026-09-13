extends TextureRect

@export var _idle_texture: Texture2D
@export var _pressed_texture: Texture2D
@export var _success_texture: Texture2D
@export var _failed_texture: Texture2D


func _switch_to_idle() -> void:
	texture = _idle_texture


func _switch_to_pressed() -> void:
	texture = _pressed_texture


func _switch_to_success() -> void:
	texture = _success_texture


func _switch_to_failed() -> void:
	texture = _failed_texture
