extends Control

@export var _move_range := 64.0

@export_range(0.01, 1.0, 0.01, "suffix:s") var _animation_duration := 0.5

@export_range(0.0, 1.0, 0.1, "suffix:s") var _pause_duration := 0.5

@onready var _start_text: Label = $StartText


## 開始の文字を右から中央、中央から左へ一度流し、演出終了まで待機する。
func start_animation_async() -> void:
	_start_text.text = "START"
	show()
	var center_position := _start_text.position
	var move_distance := size.x + _move_range
	_start_text.position.x = center_position.x + move_distance
	_start_text.self_modulate = Color.TRANSPARENT

	var animation := create_tween().set_parallel(true)
	animation.tween_property(
			_start_text, "position", center_position, _animation_duration
	)
	animation.tween_property(
			_start_text, "self_modulate", Color.WHITE, _animation_duration
	)
	await animation.finished

	await get_tree().create_timer(_pause_duration).timeout

	animation = create_tween().set_parallel(true)
	animation.tween_property(
			_start_text, "position",
			center_position - Vector2(move_distance, 0.0), _animation_duration
	)
	animation.tween_property(
			_start_text, "self_modulate", Color.TRANSPARENT, _animation_duration
	)
	await animation.finished
	hide()
	_start_text.position = center_position
