extends Timer

## 残り時間が変更時残り時間を通知。
signal remained_time_changed(remained_time: float)

## 残り時間が変更時残り時間の制限時間に対する割合を通知。
signal remained_rate_changed(remained_rate: float)

var _reciprocal: float


func _ready() -> void:
	_reciprocal = 1.0 / wait_time
	timeout.connect(_on_timeout)


func _process(delta: float) -> void:
	if is_stopped():
		return
	remained_time_changed.emit(time_left)
	remained_rate_changed.emit(time_left * _reciprocal)


func start_timer() -> void:
	start()


func stop_timer() -> void:
	stop()


func _on_timeout() -> void:
	remained_time_changed.emit(0.0)
	remained_rate_changed.emit(0.0)
