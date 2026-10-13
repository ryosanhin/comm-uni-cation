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
	await _test_parallel_requests()
	_runner.change_test_name("async_resource_loader")
	var loader := Loader.new(process_frame)
	var scene := loader.create_request(SCENE_UID, "PackedScene")
	await _wait_for_request(scene)
	_runner.assert_true(scene.resource is PackedScene, "UIDからPackedSceneを取得できる")
	_runner.assert_true(scene.is_success(), "読み込み成功を判別できる")
	_runner.assert_equal(scene.error_code, Loader.ErrorCode.OK, "成功コードを返す")
	_runner.assert_equal(Loader.resolve_resource_path(SCENE_UID), SCENE_PATH, "UIDを現在のパスへ解決できる")
	_runner.assert_equal(Loader.resolve_resource_path(SCENE_PATH), SCENE_PATH, "UIDと通常のパスを同じパスへ統一する")
	var invalid := loader.create_request("uid://invalid")
	await _wait_for_request(invalid)
	_runner.assert_equal(invalid.error_code, Loader.ErrorCode.RESOURCE_NOT_FOUND, "無効なUIDはリソース未検出として返す")
	_runner.assert_equal(invalid.resource_path, "uid://invalid", "失敗したUIDを保持する")
	var unknown_uid := ResourceUID.create_id()
	var unknown := loader.create_request(ResourceUID.id_to_text(unknown_uid))
	await _wait_for_request(unknown)
	_runner.assert_equal(unknown.error_code, Loader.ErrorCode.RESOURCE_NOT_FOUND, "未登録のUIDも安全に失敗する")
	var resource := loader.create_request(RESOURCE_PATH)
	await _wait_for_request(resource)
	_runner.assert_true(resource.resource is Resource, "シーン以外のResourceも取得できる")
	var missing := loader.create_request("res://tests/resource_loading/missing.tres")
	await _wait_for_request(missing)
	_runner.assert_equal(missing.error_code, Loader.ErrorCode.RESOURCE_NOT_FOUND, "存在しないパスのエラーコードを返す")
	_runner.assert_false(missing.is_success(), "失敗結果を判別できる")
	_runner.assert_null(missing.resource, "失敗時はResourceを持たない")
	_runner.assert_equal(missing.resource_path, "res://tests/resource_loading/missing.tres", "失敗したパスを保持する")
	var empty := loader.create_request("")
	await _wait_for_request(empty)
	_runner.assert_true(empty.is_completed(), "即時失敗でも完了状態を保持する")
	_runner.assert_equal(empty.error_code, Loader.ErrorCode.EMPTY_PATH, "空のパスは未指定として区別する")
	var failed := loader.create_request("res://tests/resource_loading/non_scene.tres", "PackedScene")
	await _wait_for_request(failed)
	_runner.assert_equal(failed.error_code, Loader.ErrorCode.LOAD_FAILED, "読み込み開始後の失敗をコードで返す")
	_runner.assert_null(failed.resource, "読み込み失敗時もResourceを持たない")
	var reloaded := loader.create_request(SCENE_PATH, "PackedScene")
	await _wait_for_request(reloaded)
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
	var result := loader.create_request("res://tests/resource_loading/timer_resource.tres")
	await _wait_for_request(result)
	_runner.assert_true(result.is_success(), "Timerのtimeoutを渡して読み込める")
	_runner.assert_true(result.resource is Resource, "読み込んだResourceを受け取れる")
	timer.queue_free()


## 完了済みのリクエストも、シグナルを待ち逃さず受け取る。[br]
## [param request]: 完了を待つリクエスト
func _wait_for_request(request: Loader.LoadRequest) -> void:
	if not request.is_completed():
		await request.completed


## 同じリソースへの複数要求も、それぞれのリクエストで結果を受け取れる。
func _test_parallel_requests() -> void:
	_runner.change_test_name("parallel_requests")
	var loader := Loader.new(process_frame)
	var first := loader.create_request(SCENE_UID, "PackedScene")
	var second := loader.create_request(SCENE_PATH, "PackedScene")
	var other := loader.create_request(RESOURCE_PATH)
	_runner.assert_false(is_same(first, second), "同じリソースでも別のリクエストを生成する")
	# 生成元のローダーを解放しても、各リクエストは独立して完了する。
	loader = null
	await _wait_for_request(first)
	await _wait_for_request(second)
	await _wait_for_request(other)
	_runner.assert_true(first.is_success() and second.is_success(), "同じリソースへの要求を両方受け取れる")
	_runner.assert_same(first.resource, second.resource, "標準キャッシュの同じResourceを受け取る")
	_runner.assert_true(other.is_success(), "別リソースへの要求も並行して受け取れる")
	_runner.assert_true(first.is_completed() and second.is_completed() and other.is_completed(), "各リクエストの完了を確認できる")
	_runner.assert_true(first.resource is PackedScene, "リクエスト自身が結果を保持する")
