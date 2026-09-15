extends TextureProgressBar

@export var gradient: Gradient

func update_progress(progress: float) -> void:
	value = progress
	var color := gradient.sample(value)
	tint_progress = color
