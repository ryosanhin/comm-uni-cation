extends Node

@export var _morse_game: MorseGame
var _scene_controller: SceneController


func inject_dependency(scene_controller: SceneController) -> void:
	_scene_controller = scene_controller
	_morse_game.quit_requested.connect(_back_to_title)
	if scene_controller.is_changing:
		await scene_controller.scene_changed
		_morse_game.start_game()


func _back_to_title() -> void:
	_scene_controller.change_main_scene(SceneEnums.Id.TITLE, TransitionEnums.Id.NORMAL)
