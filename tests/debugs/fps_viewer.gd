extends Label


func _process(delta: float) -> void:
	text = "fps: %d" % Engine.get_frames_per_second()
