extends SceneTree

const Runner := preload("res://tests/test_runner.gd")
const GameScene := preload("res://scenes/games/game.tscn")

var _runner := Runner.new(true)


## 開始演出前後のゲーム進行と、時間切れ後の停止を確認する。
func _initialize() -> void:
	await _test_start_animation()
	await _test_result()
	await _runner.finish(self, "game_overlays")


## 開始演出が終わるまで入力とタイマーを止め、終了後に一度だけ出題する。
func _test_start_animation() -> void:
	_runner.change_test_name("start_animation")
	var game: MorseGame = GameScene.instantiate()
	var timer: Timer = game.get_node("GameTimer")
	var animation: Control = game.get_node("Overlay/StartAnimation")
	game.start_automatically = true
	animation._animation_duration = 0.05
	animation._pause_duration = 0.2
	var started := [0]
	game.question_started.connect(func(_question: String) -> void: started[0] += 1)
	root.add_child(game)
	await process_frame

	_runner.assert_true(timer.is_stopped(), "演出中は制限時間を消費しない")
	_runner.assert_false(game._accepting_input, "演出中は入力を受け付けない")
	await create_timer(0.1).timeout
	_runner.assert_equal(started[0], 0, "演出終了前には問題を開始しない")
	_runner.assert_true(timer.is_stopped(), "演出終了前はタイマーを開始しない")

	await create_timer(0.3).timeout
	_runner.assert_equal(started[0], 1, "演出終了後に一度だけ問題を開始する")
	_runner.assert_false(timer.is_stopped(), "演出終了後にタイマーを開始する")
	game.queue_free()
	await process_frame


## 時間切れ時の結果表示と、終了後に入力・出題・集計が再開しないことを確認する。
func _test_result() -> void:
	_runner.change_test_name("result")
	var game: MorseGame = GameScene.instantiate()
	var input: MorseInput = game.get_node("MorseInput")
	var timer: Timer = game.get_node("GameTimer")
	var ufo: Sprite2D = game.get_node("Ufo")
	var panel: Panel = game.get_node("Overlay/ResultPanel")
	var finish_animation: Control = game.get_node("Overlay/FinishAnimation")
	finish_animation._animation_duration = 0.05
	finish_animation._pause_duration = 0.2
	panel._pause_duration = 0.05
	game.start_automatically = false
	root.add_child(game)
	await process_frame

	_runner.assert_false(panel.visible, "ゲーム中はリザルトを隠す")
	game.start_phrase("A")
	ufo.entered.emit()
	input.character_completed.emit(MorseCode.encode("A"), "A")
	input.character_completed.emit(MorseCode.encode("A"), "A")
	_runner.assert_equal(game._completed_question_count, 1, "一問の成功を一度だけ集計する")

	timer.start(0.05)
	await timer.timeout
	_runner.assert_true(finish_animation.visible, "時間切れで終了演出を開始する")
	_runner.assert_false(panel.visible, "終了演出中はリザルトを表示しない")
	_runner.assert_false(game._accepting_input, "時間切れで入力を停止する")

	# 重複した時間切れ通知の後も、結果表示まで正常に進む。
	game._on_timed_out()
	await create_timer(0.4).timeout
	_runner.assert_false(finish_animation.visible, "終了演出を完了する")
	_runner.assert_true(panel.visible, "終了演出の完了後にリザルトを表示する")

	var started := [0]
	game.question_started.connect(func(_question: String) -> void: started[0] += 1)
	ufo.exited.emit()
	ufo.entered.emit()
	input.character_completed.emit(MorseCode.encode("A"), "A")
	_runner.assert_equal(started[0], 0, "終了後の退場通知で次の問題を開始しない")
	_runner.assert_false(game._accepting_input, "終了後の入場通知で入力を再開しない")
	_runner.assert_equal(game._completed_question_count, 1, "終了後は成功数が増えない")

	game.queue_free()
	await process_frame
