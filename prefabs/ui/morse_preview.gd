extends PanelContainer

@onready var preview_line: LineEdit = $LineEdit

var _preview_codes: PackedStringArray = []

func append_dot() -> void:
	_preview_codes.append("・")
	preview_line.text = " ".join(_preview_codes)


func change_to_dash() -> void:
	if _preview_codes.is_empty():
		return
	_preview_codes[-1] = "―"
	preview_line.text = " ".join(_preview_codes)


func clear(_code: int, _character: String) -> void:
	_preview_codes.clear()
	preview_line.text = ""
