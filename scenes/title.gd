extends Node

@export var _checkbox: CheckBox
@export var _start_button: Button
@export var _copyrighs_button: Button

@export var _copyrights_viewer: PackedScene

var _scene_contoller: SceneController

var _is_loaded: bool

func inject_dependency(scene_controller: SceneController) -> void:
	_scene_contoller = scene_controller
	
	_checkbox.toggled.connect(_change_language)
	_checkbox.set_pressed_no_signal(TranslationServer.get_locale() == "en")
	
	_start_button.pressed.connect(_load_main_scene)
	_copyrighs_button.pressed.connect(_show_copyrights)


func _change_language(is_english: bool) -> void:
	if is_english:
		TranslationServer.set_locale("en")
	else:
		TranslationServer.set_locale("ja")
	


func _load_main_scene() -> void:
	if _is_loaded:
		return
	_scene_contoller.change_main_scene(SceneEnums.Id.MAIN_GAME, TransitionEnums.Id.NORMAL)
	_is_loaded =true


func _show_copyrights() -> void:
	var node := _copyrights_viewer.instantiate()
	self.add_child(node)
