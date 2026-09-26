extends Node

signal scene_change_started(scene_id: SceneEnums.Id)
signal scene_changed(scene_id: SceneEnums.Id)

@export var _scene_database: SceneDatabase

@onready var _transition_controller: TransitionController = $TransitionController
@export var _main_scenes: Node

@export_range(0.0, 10.0) var _transition_duration := 1.0

var _current_main_scene: SceneEnums.Id = SceneEnums.Id.INVALID
var current_main_scene: SceneEnums.Id:
	get:
		return _current_main_scene

var _is_changing := false
var is_changing: bool:
	get:
		return _is_changing


## 該当シーンが読み込まれているか[br]
##[param scene_id]: シーンのID
func is_loaded(scene_id: SceneEnums.Id) -> bool:
	var data := _scene_database.get_scene_data(scene_id)

	if data == null or data.scene == null:
		return false

	for scene: Node in _main_scenes.get_children():
		if scene.scene_file_path == data.scene.resource_path:
			return true

	return false


## シーン切り替え[br]
##[param scene_id]: シーンのID[br]
##[param transitino_id]: 遷移エフェクトのID[br]
## returns: await 可能
func change_main_scene(
	scene_id: SceneEnums.Id,
	transition_id: TransitionEnums.Id
) -> void:
	if _is_changing:
		return

	if is_loaded(scene_id):
		return

	var data := _scene_database.get_scene_data(scene_id)

	if data == null or data.scene == null:
		push_error("切り替え先のPackedSceneが設定されていません")
		return

	_is_changing = true
	scene_change_started.emit(scene_id)

	await _transition_controller.fade_in(
		transition_id,
		_transition_duration
	)

	var next_scene := data.scene.instantiate()

	if next_scene == null:
		push_error("シーンの生成に失敗しました")

		await _transition_controller.fade_out(
			transition_id,
			_transition_duration
		)

		_is_changing = false
		return

	for current_scene: Node in _main_scenes.get_children():
		_main_scenes.remove_child(current_scene)
		current_scene.queue_free()

	_main_scenes.add_child(next_scene)

	# add_child()によって_readyまで完了した後、次のフレームまで待って遷移を再開する。
	await get_tree().process_frame

	_current_main_scene = scene_id

	await _transition_controller.fade_out(
		transition_id,
		_transition_duration
	)

	_is_changing = false
	scene_changed.emit(scene_id)


## 注入先から非同期のシーン切り替えを開始するための同期ラッパー。
func _request_scene_change(
	scene_id: SceneEnums.Id,
	transition_id: TransitionEnums.Id,
) -> void:
	change_main_scene(scene_id, transition_id)
