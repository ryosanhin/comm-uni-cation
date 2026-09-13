extends Sprite2D

@export var init_position: Vector2
@export var main_position: Vector2
@export var exit_position: Vector2

@export var entering_time: float

@export var exiting_time: float

## 画面出現アニメーション終了時のシグナル
signal entered

## 画面退場アニメーション終了時のシグナル
signal exited


func _enter_anima() -> void:
	scale = Vector2.ZERO
	position = init_position
	var tween = create_tween().set_parallel(true)
	tween.tween_property(
			self,
			"scale",
			Vector2.ONE,
			entering_time
	)
	tween.tween_property(
			self,
			"position",
			main_position,
			entering_time
	)
	tween.finished.connect(
			func() -> void:
				entered.emit()
	)


func _exit_anima() -> void:
	position = main_position
	var tween = create_tween()
	tween.tween_property(
			self,
			"position",
			exit_position,
			exiting_time
	)
	tween.finished.connect(
			func() -> void:
				exited.emit()
	)
