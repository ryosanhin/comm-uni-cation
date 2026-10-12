extends SceneTree

const Runner := preload("res://tests/test_runner.gd")
const Loader := preload("res://resource_loading/async_resource_loader.gd")
const SCENE_PATH := "res://tests/scene_controller/fixtures/next_scene.tscn"
const RESOURCE_PATH := "res://tests/resource_loading/example.tres"

var _runner := Runner.new(true)


## ツリーへローダーを追加してから読み込みを確認する。
func _initialize() -> void:
	call_deferred("_run_tests")


## シーン以外も読み込めることと、失敗後も再利用できることを確認する。
func _run_tests() -> void:
	_runner.change_test_name("async_resource_loader")
	var loader := Loader.new()
	root.add_child(loader)
	var scene := await loader.load_resource(SCENE_PATH, "PackedScene")
	_runner.assert_true(scene is PackedScene, "パスからPackedSceneを取得できる")
	var resource := await loader.load_resource(RESOURCE_PATH)
	_runner.assert_true(resource is Resource, "シーン以外のResourceも取得できる")
	var missing := await loader.load_resource("res://tests/resource_loading/missing.tres")
	_runner.assert_null(missing, "存在しないパスはnullを返す")
	var reloaded := await loader.load_resource(SCENE_PATH, "PackedScene")
	_runner.assert_true(reloaded is PackedScene, "読み込み完了・失敗後も同じローダーを再利用できる")
	loader.queue_free()
	await _runner.finish(self, "async_resource_loader")
