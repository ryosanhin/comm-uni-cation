extends Panel

@onready var _result_count: Label = $ResultCount


## 交信に成功したUFOの数を翻訳された単位とともに表示する。[br]
## [param count]: 交信に成功したUFOの数
func show_result(count: int) -> void:
	_result_count.text = "%d %s" % [count, tr("UNIT")]
	show()
