extends Node

const SceneEnums := preload("scene_enums.gd")
const TransitionEnums := preload("transition_controllers/transition_enums.gd")

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
	var entry := _validate_change_request(scene_id)
	if entry == null:
		return

	_is_changing = true
	scene_change_started.emit(scene_id)

	await _transition_controller.fade_in(
		transition_id,
		_transition_duration
	)

	var next_scene := _instantiate_scene(entry)

	if next_scene == null:
		await _transition_controller.fade_out(
			transition_id,
			_transition_duration
		)

		_reset_change_state()
		return

	await _replace_main_scene(next_scene)

	await _transition_controller.fade_out(
		transition_id,
		_transition_duration
	)

	_reset_change_state()
	_complete_scene_change(scene_id, next_scene)


## シーン切り替えリクエストを検証し、切り替え先のエントリーを返す。
func _validate_change_request(scene_id: SceneEnums.Id) -> SceneData:
	if _is_changing or scene_id == _current_main_scene:
		return null

	var entry := _scene_database.get_scene_data(scene_id)
	if entry == null:
		return null

	if entry.scene == null:
		push_error("切り替え先のPackedSceneが設定されていません")
		return null

	return entry


## PackedSceneから切り替え先のノードを生成する。
func _instantiate_scene(entry: SceneData) -> Node:
	var next_scene := entry.scene.instantiate()
	if next_scene == null:
		push_error("シーンの生成に失敗しました")

	return next_scene


## 現在のメインシーンを解放し、切り替え先のノードに入れ替える。
func _replace_main_scene(next_scene: Node) -> void:
	for current_scene: Node in _main_scenes.get_children():
		_main_scenes.remove_child(current_scene)
		current_scene.queue_free()

	_main_scenes.add_child(next_scene)

	# add_child()によって_readyまで完了した後、次のフレームまで待って遷移を再開する。
	await get_tree().process_frame


## シーン切り替えの完了を記録し、通知する。
func _complete_scene_change(scene_id: SceneEnums.Id, next_scene: Node) -> void:
	assert(next_scene.get_parent() == _main_scenes)
	_current_main_scene = scene_id
	scene_changed.emit(scene_id)


## シーン切り替え中の状態を解除する。
func _reset_change_state() -> void:
	_is_changing = false


## 注入先から非同期のシーン切り替えを開始するための同期ラッパー。
func _request_scene_change(
	scene_id: SceneEnums.Id,
	transition_id: TransitionEnums.Id,
) -> void:
	change_main_scene(scene_id, transition_id)
