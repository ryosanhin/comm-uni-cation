extends Control

@export var _move_range := 64.0

@export_range(0.01, 1.0, 0.01, "suffix:s") var _animation_duration := 0.5

@export_range(0.0, 1.0, 0.1, "suffix:s") var _pause_duration := 0.5

@onready var _lebel: Label = $Label


## 開始の文字を右から中央、中央から左へ一度流し、演出終了まで待機する。
func animation_async() -> void:
	show()
	var center_position := _lebel.position
	var move_distance := _move_range
	_lebel.position.x = center_position.x + move_distance
	_lebel.self_modulate = Color.TRANSPARENT

	var animation := create_tween().set_parallel(true)
	animation.tween_property(
			_lebel, "position", center_position, _animation_duration
	)
	animation.tween_property(
			_lebel, "self_modulate", Color.WHITE, _animation_duration
	)
	await animation.finished

	await get_tree().create_timer(_pause_duration).timeout

	animation = create_tween().set_parallel(true)
	animation.tween_property(
			_lebel, "position",
			center_position - Vector2(move_distance, 0.0), _animation_duration
	)
	animation.tween_property(
			_lebel, "self_modulate", Color.TRANSPARENT, _animation_duration
	)
	await animation.finished
	hide()
	_lebel.position = center_position
