extends TextureProgressBar

@export var gradient: Gradient

var _reciprocal_time_limit: float


func set_time_limit(time_limit: float) -> void:
	# 一旦現在の実際の値を近似
	var tmp_actual_value := value / _reciprocal_time_limit
	# 除算より乗算の方が早い？
	_reciprocal_time_limit = 1.0 / time_limit
	
	update_progress(tmp_actual_value)


func update_progress(remaining_time: float) -> void:
	value = remaining_time * _reciprocal_time_limit
	var color := gradient.sample(value)
	tint_progress = color
