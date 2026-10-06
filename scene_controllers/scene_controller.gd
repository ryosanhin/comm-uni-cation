extends Node
class_name SceneController

const SceneEnums := preload("scene_enums.gd")
const SceneRegistry := preload("scene_registry.gd")
const TransitionController := preload("transition_controllers/transition_controller.gd")
const TransitionEnums := preload("transition_controllers/transition_enums.gd")

signal scene_change_started(scene_id: SceneEnums.Id)
signal scene_changed(scene_id: SceneEnums.Id)

@export var _scene_registry: SceneRegistry

@export var _transition_controller: TransitionController
@export var _main_scenes_root: Node

@export_range(0.0, 10.0) var _transition_duration := 1.0

var current_main_scene_id: SceneEnums.Id = SceneEnums.Id.INVALID

var is_changing := false


## 該当シーンが読み込まれているか[br]
##[param scene_id]: シーンのID
func is_loaded(scene_id: SceneEnums.Id) -> bool:
	var entry := _scene_registry.get_scene_data(scene_id)

	if entry == null or entry.scene == null:
		return false

	for scene in _main_scenes_root.get_children():
		if scene.scene_file_path == entry.scene.resource_path:
			return true

	return false


## シーン切り替え[br]
## [param scene_id]: シーンのID[br]
## [param transitino_id]: 遷移エフェクトのID[br]
## returns: await 可能
func change_main_scene(
	scene_id: SceneEnums.Id,
	transition_id: TransitionEnums.Id
) -> void:
	var entry := _resolve_scene_entry(scene_id)
	if entry == null:
		return

	is_changing = true
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

	await _replace_main_scene(scene_id, next_scene)

	await _transition_controller.fade_out(
		transition_id,
		_transition_duration
	)

	_reset_change_state()
	_complete_scene_change(scene_id)


## シーン切り替えリクエストを検証し、切り替え先のエントリーを返す。
func _resolve_scene_entry(scene_id: SceneEnums.Id) -> SceneEntry:
	if is_changing or scene_id == current_main_scene_id:
		return null

	var entry := _scene_registry.get_scene_data(scene_id)
	if entry == null:
		return null

	if entry.scene == null:
		push_error("切り替え先のPackedSceneが設定されていません")
		return null

	return entry


## PackedSceneから切り替え先のノードを生成する。
func _instantiate_scene(entry: SceneEntry) -> Node:
	var next_scene := entry.scene.instantiate()
	if next_scene == null:
		push_error("シーンの生成に失敗しました")

	return next_scene


## 現在のメインシーンを解放し、切り替え先のノードに入れ替える。
func _replace_main_scene(next_scene_id: SceneEnums.Id, next_scene: Node) -> void:
	for current_scene: Node in _main_scenes_root.get_children():
		_main_scenes_root.remove_child(current_scene)
		current_scene.queue_free()

	_main_scenes_root.add_child(next_scene)

	# add_child()によって_readyまで完了した後、次のフレームまで待って遷移を再開する。
	await get_tree().process_frame
	current_main_scene_id = next_scene_id


## シーン切り替えの完了を記録し、通知する。
func _complete_scene_change(scene_id: SceneEnums.Id) -> void:
	scene_changed.emit(scene_id)


## シーン切り替え中の状態を解除する。
func _reset_change_state() -> void:
	is_changing = false
