extends Resource
class_name TransitionData

@export var _transition_texture: Texture2D
var transition_texture: Texture2D:
	get:
		return _transition_texture

@export var _color: Color = Color.BLACK
var color: Color = Color.BLACK:
	get:
		return _color
