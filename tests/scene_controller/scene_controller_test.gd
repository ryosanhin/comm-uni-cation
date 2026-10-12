extends SceneTree

const Runner := preload("res://tests/test_runner.gd")
const ControllerScene := preload("res://scene_controllers/scene_controller.tscn")

var _runner := Runner.new(true)


## 任意のIDでのシーン交換と、暗転中・演出終了後の通知を確認する。
func _initialize() -> void:
	call_deferred("_run_tests")


## ノード追加が可能になってからテストを開始する。
func _run_tests() -> void:
	await _test_scene_replacement()
	await _runner.finish(self, "scene_controller")


## 交換完了時の状態、通知順序、および連続要求の抑制を確認する。
func _test_scene_replacement() -> void:
	_runner.change_test_name("scene_replacement")
	var controller: SceneController = ControllerScene.instantiate()
	var scenes_root := Node.new()
	var old_scene := Node.new()
	scenes_root.add_child(old_scene)
	root.add_child(scenes_root)

	var template := Node.new()
	template.name = "NextScene"
	var packed := PackedScene.new()
	_runner.assert_equal(packed.pack(template), OK, "交換先シーンを作成できる")
	template.free()
	var entry := SceneEntry.new()
	entry.scene = packed
	var registry := SceneRegistry.new()
	registry._data_dict[&"other_project_level"] = entry

	var transitions := TransitionRegistry.new()
	transitions._entries[&"other_project_effect"] = TransitionEntry.new()
	var transition := controller.get_node("TransitionController")
	transition._transition_registry = transitions
	controller._scene_registry = registry
	controller._main_scenes_root = scenes_root
	controller.init_scene_id = &"initial_level"
	controller._transition_duration = 0.05

	var events: Array[StringName] = []
	controller.scene_change_started.connect(func(id: StringName) -> void:
		events.append(&"started")
		_runner.assert_equal(id, &"other_project_level", "開始通知に要求IDを渡す")
		_runner.assert_same(scenes_root.get_child(0), old_scene, "開始時には旧シーンが残る")
	)
	controller.scene_replaced.connect(func(id: StringName) -> void:
		events.append(&"replaced")
		_runner.assert_equal(id, &"other_project_level", "交換通知に要求IDを渡す")
		_runner.assert_equal(controller.current_main_scene_id, id, "交換通知前に現在IDを更新する")
		_runner.assert_equal(scenes_root.get_child_count(), 1, "専用ルートには新シーンだけを置く")
		_runner.assert_equal(scenes_root.get_child(0).name, &"NextScene", "新シーンが追加済みである")
		_runner.assert_true(controller.is_changing, "交換通知時には遷移中である")
		_runner.assert_true(transition._transition_rect.visible, "交換通知時には画面を覆っている")
		_runner.assert_equal(transition._material.get_shader_parameter(&"Value"), 1.0, "画面を戻す演出は未開始である")
	)
	controller.scene_changed.connect(func(id: StringName) -> void:
		events.append(&"changed")
		_runner.assert_equal(id, &"other_project_level", "完了通知に要求IDを渡す")
		_runner.assert_false(controller.is_changing, "完了通知時には遷移中状態を解除する")
		_runner.assert_false(transition._transition_rect.visible, "完了通知時には画面を戻している")
	)
	root.add_child(controller)
	_runner.assert_equal(controller.current_main_scene_id, &"initial_level", "外部指定の初期IDを使用する")

	controller.change_main_scene(&"other_project_level", &"other_project_effect")
	controller.change_main_scene(&"other_project_level", &"other_project_effect")
	await controller.scene_changed
	_runner.assert_array(events, [&"started", &"replaced", &"changed"], "通知順序を守り、重複要求を拒否する")
	await controller.change_main_scene(&"other_project_level", &"other_project_effect")
	_runner.assert_equal(events.size(), 3, "現在のシーンへの再要求では通知しない")
	controller.queue_free()
	scenes_root.queue_free()
	await process_frame
