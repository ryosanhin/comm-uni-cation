extends Sprite2D

## 画面出現アニメーション終了時のシグナル
signal entered

## 画面退場アニメーション終了時のシグナル
signal exited

@export var init_position: Vector2
@export var main_position: Vector2
@export var exit_position: Vector2

@export var entering_time: float

@export var exiting_time: float

var _animation: Tween


func _enter_anima(_phrase: String = "") -> void:
	_stop_animation()
	visible = true
	scale = Vector2.ZERO
	position = init_position
	_animation = create_tween().set_parallel(true)
	_animation.tween_property(
		self,
		"scale",
		Vector2.ONE,
		entering_time
	)
	_animation.tween_property(
		self,
		"position",
		main_position,
		entering_time
	)
	_animation.finished.connect(
		func() -> void:
			entered.emit()
	)


func _exit_anima(_phrase: String = "") -> void:
	_stop_animation()
	position = main_position
	_animation = create_tween()
	_animation.tween_property(
		self,
		"position",
		exit_position,
		exiting_time
	)
	_animation.finished.connect(
		func() -> void:
			exited.emit()
	)


## 問題が途中で切り替わった場合に、実行中のアニメーションを停止する。
func _stop_animation() -> void:
	if _animation != null and _animation.is_valid():
		_animation.kill()
