extends SceneTree

const Runner := preload("res://tests/test_runner.gd")
const GameScene := preload("res://scenes/games/game.tscn")

var _runner := Runner.new(true)


## 符号変換、ゲーム進行、演出の連動を確認する。
func _initialize() -> void:
	_test_morse_code()
	await _test_game_progress()
	await _test_game_scene_presentation()
	await _runner.finish(self, "morse_game")


## モールス符号の変換と、対応しない符号の扱いを確認する。
func _test_morse_code() -> void:
	_runner.change_test_name("morse_code")
	_runner.assert_equal(MorseCode.encode("A"), 0b1_01, "文字をモールス符号に変換する")
	_runner.assert_equal(MorseCode.decode(0b1_01), "A", "モールス符号を文字に変換する")
	_runner.assert_equal(MorseCode.decode(0b111_111_1), "", "対応しない符号は空文字を返す")


## 入力の受付、文字の成否、問題の完了を確認する。
func _test_game_progress() -> void:
	_runner.change_test_name("game_progress")
	var game_scene := GameScene.instantiate()
	var game: MorseGame = game_scene
	var input: MorseInput = game_scene.get_node("MorseInput")
	game.start_automatically = false
	root.add_child(game_scene)
	await process_frame

	var counts := [0, 0, 0, 0]
	game.question_started.connect(func(_p: String) -> void: counts[3] += 1)
	game.character_succeeded.connect(
		func(_i: int, _e: String, _c: int) -> void: counts[0] += 1
	)
	game.character_failed.connect(
		func(_i: int, _e: String, _a: String, _c: int) -> void: counts[1] += 1
	)
	game.question_succeeded.connect(func(_p: String) -> void: counts[2] += 1)

	game.start_phrase("a b!")
	_runner.assert_equal(counts[3], 1, "問題の開始を一度だけ通知する")
	# UFO入場前の入力は受け付けない。
	input.character_completed.emit(MorseCode.encode("A"), "A")
	_runner.assert_equal(counts[0], 0, "UFO入場前の入力で成功を通知しない")
	_runner.assert_equal(game._current_character_index, 0, "UFO入場前の入力で文字を進めない")
	game._on_ufo_entered()
	input.character_completed.emit(MorseCode.encode("T"), "T")
	_runner.assert_equal(counts[1], 1, "誤った文字の入力で失敗を通知する")
	_runner.assert_equal(game._current_character_index, 0, "失敗した入力で文字を進めない")
	input.character_completed.emit(MorseCode.encode("A"), "A")
	_runner.assert_equal(counts[0], 1, "正しい文字の入力で成功を通知する")
	_runner.assert_equal(game._current_character_index, 2, "成功後は空白を飛ばして次の文字に進む")
	input.character_completed.emit(MorseCode.encode("B"), "B")
	_runner.assert_equal(counts[2], 1, "すべての文字の成功で問題の完了を通知する")
	_runner.assert_array(
		game.get_accepted_codes(),
		[MorseCode.encode("A"), MorseCode.encode("B")],
		"成功した文字の符号を入力順に保持する",
	)
	input.character_completed.emit(MorseCode.encode("B"), "B")
	_runner.assert_equal(counts[2], 1, "完了後の入力で問題の完了を再通知しない")

	game_scene.queue_free()
	await process_frame


## ゲームシーンの演出が進行シグナルと連動することを確認する。
func _test_game_scene_presentation() -> void:
	_runner.change_test_name("game_scene_presentation")
	var game_scene := GameScene.instantiate()
	game_scene.start_automatically = false
	root.add_child(game_scene)
	await process_frame

	var scene_game: MorseGame = game_scene
	var scene_input: MorseInput = game_scene.get_node("MorseInput")
	var label: RichTextLabel = game_scene.get_node(
		"QuestionBubble/MarginContainer/VBoxContainer/RichTextLabel"
	)
	var face: TextureRect = game_scene.get_node("NeoUniFace")
	var ufo: Sprite2D = game_scene.get_node("Ufo")
	var preview: LineEdit = game_scene.get_node("MorsePreview/MarginContainer/LineEdit")

	scene_game.start_phrase("AB")
	_runner.assert_true((ufo.get("_animation") as Tween).is_valid(), "問題の開始でUFOの入場演出を開始する")
	# 入場アニメーション中の入力は無視し、entered後に受付を開始する。
	scene_input.character_completed.emit(MorseCode.encode("A"), "A")
	_runner.assert_equal(scene_game._current_character_index, 0, "入場演出中の入力で文字を進めない")
	ufo.entered.emit()
	_runner.assert_true(label.text.contains("[font_size=72]A[/font_size]"), "現在の文字を大きく表示する")
	_runner.assert_true(label.text.contains("[color=#808080]B[/color]"), "未入力の文字を灰色で表示する")

	var idle_texture := face.texture
	scene_input.key_pressed.emit()
	_runner.assert_not_equal(face.texture, idle_texture, "キーを押すと表情が変わる")
	_runner.assert_equal(preview.text, "・", "キーを押すと短点を表示する")
	scene_input.dash_threshold_reached.emit()
	_runner.assert_equal(preview.text, "―", "長押しで長点に表示を変える")
	scene_input.key_released.emit(false)
	_runner.assert_equal(face.texture, idle_texture, "キーを離すと元の表情に戻る")

	scene_input.character_completed.emit(MorseCode.encode("A"), "A")
	_runner.assert_true(preview.text.is_empty(), "文字の確定で入力プレビューを消す")
	await process_frame
	_runner.assert_true(label.text.contains("A[font_size=72]B[/font_size]"), "成功後は次の文字を大きく表示する")
	scene_input.character_completed.emit(MorseCode.encode("T"), "T")
	var failed_texture := face.texture
	_runner.assert_not_equal(failed_texture, idle_texture, "失敗時は表情を変える")
	scene_input.character_completed.emit(MorseCode.encode("B"), "B")
	_runner.assert_not_equal(face.texture, failed_texture, "成功時は失敗時の表情から変わる")
	_runner.assert_true((ufo.get("_animation") as Tween).is_valid(), "問題の完了でUFOの退場演出を開始する")
	# 退場後はCSVから次の問題を出題し、再入場までは入力を止める。
	ufo.exited.emit()
	_runner.assert_true(
		scene_game._question.to_lower() in scene_game._question_loader.get_all_questions(),
		"退場後はCSVに含まれる次の問題を出題する",
	)
	var next_index := scene_game._current_character_index
	scene_input.character_completed.emit(MorseCode.encode("T"), "T")
	_runner.assert_equal(scene_game._current_character_index, next_index, "再入場前の入力で文字を進めない")

	game_scene.queue_free()
	await process_frame
