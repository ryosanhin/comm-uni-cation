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
	_runner.assert_true(scene.resource is PackedScene, "パスからPackedSceneを取得できる")
	_runner.assert_true(scene.is_success(), "読み込み成功を判別できる")
	_runner.assert_equal(scene.error_code, Loader.ErrorCode.OK, "成功コードを返す")
	var resource := await loader.load_resource(RESOURCE_PATH)
	_runner.assert_true(resource.resource is Resource, "シーン以外のResourceも取得できる")
	var missing := await loader.load_resource("res://tests/resource_loading/missing.tres")
	_runner.assert_equal(missing.error_code, Loader.ErrorCode.RESOURCE_NOT_FOUND, "存在しないパスのエラーコードを返す")
	_runner.assert_false(missing.is_success(), "失敗結果を判別できる")
	_runner.assert_null(missing.resource, "失敗時はResourceを持たない")
	_runner.assert_equal(missing.resource_path, "res://tests/resource_loading/missing.tres", "失敗したパスを保持する")
	var empty := await loader.load_resource("")
	_runner.assert_equal(empty.error_code, Loader.ErrorCode.EMPTY_PATH, "空のパスは未指定として区別する")
	var failed := await loader.load_resource("res://tests/resource_loading/non_scene.tres", "PackedScene")
	_runner.assert_equal(failed.error_code, Loader.ErrorCode.LOAD_FAILED, "読み込み開始後の失敗をコードで返す")
	_runner.assert_null(failed.resource, "読み込み失敗時もResourceを持たない")
	var reloaded := await loader.load_resource(SCENE_PATH, "PackedScene")
	_runner.assert_true(reloaded.resource is PackedScene, "読み込み完了・失敗後も同じローダーを再利用できる")
	loader.queue_free()
	await _runner.finish(self, "async_resource_loader")
