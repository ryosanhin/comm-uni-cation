extends Panel

@export var _result_title: Label
@export var _result_count: Label
@export var _button: Button

@export_range(0.01, 1.0, 0.01, "suffix:s") var _pause_duration := 0.5

var _scene_controller: SceneController
var _is_loaded: bool


func inject_dependency(scene_controller: SceneController) -> void:
	_scene_controller = scene_controller
	_button.pressed.connect(_back_to_title)


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


func _back_to_title() -> void:
	if _is_loaded:
		return
	_scene_controller.change_main_scene(SceneEnums.Id.TITLE, TransitionEnums.Id.NORMAL)
	_is_loaded = true
