extends Control

@onready var _count_down_text: RichTextLabel = $TextureRect/RichTextLabel

@export var _move_range: float

@export_range(0.0, 1.0, 0.1, "suffix: s") var _animation_duration := 0.5


func start_animation_async() -> void:
	for i in range(3, 0, -1):
		await _cut_in_async(str(i))


func _cut_in_async(text: String) -> void:
	var start_position := Vector2(
			_count_down_text.position.x + _move_range,
			_count_down_text.position.y
	)
	
	var end_position := _count_down_text.position
	var text_display_time := 1.0 - _animation_duration
	
	_count_down_text.text = text
	
	_count_down_text.position = start_position
	_count_down_text.self_modulate = Color.TRANSPARENT
	
	var animation = create_tween().set_parallel(true)
	animation.tween_property(
		_count_down_text,
		"position",
		end_position,
		_animation_duration
	)
	animation.tween_property(
		_count_down_text,
		"self_modulate",
		Color.WHITE,
		_animation_duration
	)
	await animation.finished
	
	await get_tree().create_timer(text_display_time).timeout
