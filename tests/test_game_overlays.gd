extends SceneTree

const Runner := preload("res://tests/test_runner.gd")
const GameScene := preload("res://scenes/games/game.tscn")

var _runner := Runner.new(true)


## 開始演出と時間切れ時のリザルトを両言語で確認する。
func _initialize() -> void:
	await _test_start_animation()
	await _test_result("ja", "機", "交信したUFOの数: ", "戻る", true)
	await _test_result("en", "UFOs", "Communicated with ", "Back", false)
	await _runner.finish(self, "game_overlays")


## 開始文字が中央で停止し、退場が終わるまでゲームが始まらないことを確認する。
func _test_start_animation() -> void:
	_runner.change_test_name("start_animation")
	TranslationServer.set_locale("ja")
	var scene := GameScene.instantiate()
	var game: MorseGame = scene.get_node("MorseGame")
	var timer: Timer = scene.get_node("GameTimer")
	var animation: Control = scene.get_node("Overlay/CountDownAnimation")
	var label: Label = animation.get_node("Label")
	animation._animation_duration = 0.05
	animation._pause_duration = 0.2
	var started := [0]
	game.question_started.connect(func(_question: String) -> void: started[0] += 1)
	root.add_child(scene)
	await process_frame
	_runner.assert_true(timer.is_stopped(), "演出中は制限時間を消費しない")
	_runner.assert_false(game._accepting_input, "演出中は入力を受け付けない")
	_runner.assert_equal(label.tr(label.text), "スタート", "STARTの翻訳を表示する")
	await create_timer(0.1).timeout
	var center_x := label.position.x
	_runner.assert_true(
			is_equal_approx(center_x + label.size.x / 2.0, animation.size.x / 2.0),
			"開始文字が画面中央に到達する"
	)
	_runner.assert_equal(label.self_modulate, Color.WHITE, "中央では不透明になる")
	await create_timer(0.05).timeout
	_runner.assert_equal(label.position.x, center_x, "中央で少し停止する")
	_runner.assert_equal(started[0], 0, "退場前には問題を開始しない")
	await create_timer(0.25).timeout
	_runner.assert_equal(started[0], 1, "一度の演出終了後に問題を開始する")
	_runner.assert_false(animation.visible, "退場後は開始文字を隠す")
	_runner.assert_equal(label.self_modulate, Color.TRANSPARENT, "退場時に透明になる")
	_runner.assert_false(timer.is_stopped(), "演出終了後にタイマーを開始する")
	scene.queue_free()
	await process_frame


## 時間切れ時の集計・翻訳・終了後の入力停止を確認する。[br]
## [param locale]: 表示言語[br]
## [param unit]: 翻訳された単位[br]
## [param title]: 翻訳された見出し[br]
## [param back]: 翻訳された戻るボタン[br]
## [param complete_question]: 一問正解させるかどうか
func _test_result(
		locale: String, unit: String, title: String, back: String,
		complete_question: bool
) -> void:
	_runner.change_test_name("result_" + locale)
	TranslationServer.set_locale(locale)
	var scene := GameScene.instantiate()
	var game: MorseGame = scene.get_node("MorseGame")
	var input: MorseInput = scene.get_node("MorseInput")
	var timer: Timer = scene.get_node("GameTimer")
	var ufo: Sprite2D = scene.get_node("Ufo")
	var panel: Panel = scene.get_node("Overlay/ResultPanel")
	var finish_animation: Control = scene.get_node("Overlay/FinishAnimation")
	finish_animation._animation_duration = 0.05
	finish_animation._pause_duration = 0.2
	panel._pause_duration = 0.05
	game.start_automatically = false
	root.add_child(scene)
	await process_frame
	_runner.assert_false(panel.visible, "ゲーム中はリザルトを隠す")
	game.start_phrase("A")
	ufo.entered.emit()
	if complete_question:
		input.character_completed.emit(MorseCode.encode("A"), "A")
		input.character_completed.emit(MorseCode.encode("A"), "A")
	timer.start(0.05)
	await timer.timeout
	_runner.assert_true(finish_animation.visible, "時間切れで終了演出をオーバーレイ表示する")
	_runner.assert_false(panel.visible, "終了演出中はリザルトを表示しない")
	_runner.assert_false(game._accepting_input, "終了演出中は入力を受け付けない")
	_runner.assert_equal(
			finish_animation.tr(finish_animation.get_node("Label").text),
			"終了" if locale == "ja" else "Finish", "FINISHの翻訳を表示する"
	)
	# 重複した時間切れ通知で演出を再生しない。
	game._on_timed_out()
	await create_timer(0.15).timeout
	_runner.assert_false(panel.visible, "終了文字の中央停止中もリザルトを隠す")
	await create_timer(0.25).timeout
	_runner.assert_false(finish_animation.visible, "終了演出が完了すると非表示になる")
	_runner.assert_true(panel.visible, "終了演出の完了後にリザルトを表示する")
	_runner.assert_equal(
			panel.get_node("ResultCount").text,
			"%d %s" % [int(complete_question), unit], "成功数と翻訳された単位を表示する"
	)
	_runner.assert_equal(
			panel.tr(panel.get_node("ResultTitle").text), title, "見出しを翻訳する"
	)
	_runner.assert_equal(
			panel.tr(panel.get_node("Button").text), back, "ボタンを翻訳する"
	)
	_runner.assert_true(scene.is_inside_tree(), "ゲーム画面を残したまま表示する")
	var started := [0]
	game.question_started.connect(func(_question: String) -> void: started[0] += 1)
	ufo.exited.emit()
	ufo.entered.emit()
	input.character_completed.emit(MorseCode.encode("A"), "A")
	_runner.assert_equal(started[0], 0, "終了後の退場通知で次の問題を開始しない")
	_runner.assert_false(game._accepting_input, "終了後の入場通知で入力を再開しない")
	_runner.assert_equal(
			game._completed_question_count, int(complete_question), "終了後は成功数が増えない"
	)
	scene.queue_free()
	await process_frame
