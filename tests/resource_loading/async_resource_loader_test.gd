extends SceneTree

const Runner := preload("res://tests/test_runner.gd")
const Loader := preload("res://async_resource_loaders/async_resource_loader.gd")
const SCENE_UID := "uid://dqw1q4y2w3h6a"
const SCENE_PATH := "res://tests/scene_controller/fixtures/next_scene.tscn"
const RESOURCE_PATH := "res://tests/resource_loading/example.tres"

var _runner := Runner.new(true)


## フレーム通知を受け取るローダーで読み込みを確認する。
func _initialize() -> void:
	call_deferred("_run_tests")


## シーン以外も読み込めることと、失敗後も再利用できることを確認する。
func _run_tests() -> void:
	_runner.change_test_name("async_resource_loader")
	var loader := Loader.new(process_frame)
	var scene := await loader.load_resource_async(SCENE_UID, "PackedScene")
	_runner.assert_true(scene.resource is PackedScene, "UIDからPackedSceneを取得できる")
	_runner.assert_true(scene.is_success(), "読み込み成功を判別できる")
	_runner.assert_equal(scene.error_code, Loader.ErrorCode.OK, "成功コードを返す")
	_runner.assert_equal(Loader.resolve_resource_path(SCENE_UID), SCENE_PATH, "UIDを現在のパスへ解決できる")
	_runner.assert_equal(Loader.resolve_resource_path(SCENE_PATH), SCENE_PATH, "UIDと通常のパスを同じパスへ統一する")
	var invalid := await loader.load_resource_async("uid://invalid")
	_runner.assert_equal(invalid.error_code, Loader.ErrorCode.RESOURCE_NOT_FOUND, "無効なUIDはリソース未検出として返す")
	_runner.assert_equal(invalid.resource_path, "uid://invalid", "失敗したUIDを保持する")
	var unknown_uid := ResourceUID.create_id()
	var unknown := await loader.load_resource_async(ResourceUID.id_to_text(unknown_uid))
	_runner.assert_equal(unknown.error_code, Loader.ErrorCode.RESOURCE_NOT_FOUND, "未登録のUIDも安全に失敗する")
	var resource := await loader.load_resource_async(RESOURCE_PATH)
	_runner.assert_true(resource.resource is Resource, "シーン以外のResourceも取得できる")
	var missing := await loader.load_resource_async("res://tests/resource_loading/missing.tres")
	_runner.assert_equal(missing.error_code, Loader.ErrorCode.RESOURCE_NOT_FOUND, "存在しないパスのエラーコードを返す")
	_runner.assert_false(missing.is_success(), "失敗結果を判別できる")
	_runner.assert_null(missing.resource, "失敗時はResourceを持たない")
	_runner.assert_equal(missing.resource_path, "res://tests/resource_loading/missing.tres", "失敗したパスを保持する")
	var empty := await loader.load_resource_async("")
	_runner.assert_equal(empty.error_code, Loader.ErrorCode.EMPTY_PATH, "空のパスは未指定として区別する")
	var failed := await loader.load_resource_async("res://tests/resource_loading/non_scene.tres", "PackedScene")
	_runner.assert_equal(failed.error_code, Loader.ErrorCode.LOAD_FAILED, "読み込み開始後の失敗をコードで返す")
	_runner.assert_null(failed.resource, "読み込み失敗時もResourceを持たない")
	var reloaded := await loader.load_resource_async(SCENE_PATH, "PackedScene")
	_runner.assert_true(reloaded.resource is PackedScene, "読み込み完了・失敗後も同じローダーを再利用できる")
	await _test_timer_signal()
	await _runner.finish(self, "async_resource_loader")


## SceneTree以外の発行元のシグナルでも再確認できる。
func _test_timer_signal() -> void:
	_runner.change_test_name("timer_signal")
	var timer := Timer.new()
	timer.wait_time = 0.01
	root.add_child(timer)
	timer.start()
	var loader := Loader.new(timer.timeout)
	var result := await loader.load_resource_async("res://tests/resource_loading/timer_resource.tres")
	_runner.assert_true(result.is_success(), "Timerのtimeoutを渡して読み込める")
	_runner.assert_true(result.resource is Resource, "読み込んだResourceを受け取れる")
	timer.queue_free()
