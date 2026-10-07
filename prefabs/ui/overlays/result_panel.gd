extends Panel

@onready var _result_title: Label = $ResultTitle
@onready var _result_count: Label = $ResultCount
@onready var _button: Button = $Button

@export_range(0.01, 1.0, 0.01, "suffix:s") var _pause_duration := 0.5


## 交信に成功したUFOの数を翻訳された単位とともに表示する。[br]
## [param count]: 交信に成功したUFOの数
func show_result(count: int) -> void:
	_result_count.hide()
	_button.hide()
	show()

	_result_title.show()
	await get_tree().create_timer(_pause_duration).timeout

	_result_count.text = "%d %s" % [count, tr("UNIT")]
	_result_count.show()
	await get_tree().create_timer(_pause_duration).timeout

	_button.show()
