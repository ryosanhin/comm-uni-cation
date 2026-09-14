extends SceneTree


func _initialize() -> void:
	assert(MorseCode.encode("A") == 0b1_01)
	assert(MorseCode.decode(0b1_01) == "A")
	assert(MorseCode.decode(0b111_111_1) == "")

	var input_scene := load("res://morse/morse_input.tscn") as PackedScene
	var input := input_scene.instantiate() as MorseInput
	root.add_child(input)
	var game := MorseGame.new()
	game.name = "MorseGame"
	game.morse_input_path = NodePath("../MorseInput")
	game.start_automatically = false
	root.add_child(game)
	await process_frame

	var counts := [0, 0, 0, 0]
	game.phrase_started.connect(func(_p: String) -> void: counts[3] += 1)
	game.character_succeeded.connect(
		func(_i: int, _e: String, _c: int) -> void: counts[0] += 1
	)
	game.character_failed.connect(
		func(_i: int, _e: String, _a: String, _c: int) -> void: counts[1] += 1
	)
	game.phrase_succeeded.connect(func(_p: String) -> void: counts[2] += 1)

	game.start_phrase("a b!")
	assert(counts[3] == 1)
	input.character_completed.emit(MorseCode.encode("T"), "T")
	assert(counts[1] == 1 and game.current_character_index == 0)
	input.character_completed.emit(MorseCode.encode("A"), "A")
	assert(counts[0] == 1 and game.current_character_index == 2)
	input.character_completed.emit(MorseCode.encode("B"), "B")
	assert(counts[2] == 1)
	assert(
		game.get_accepted_codes()
		== PackedByteArray([MorseCode.encode("A"), MorseCode.encode("B")])
	)
	input.character_completed.emit(MorseCode.encode("B"), "B")
	assert(counts[2] == 1)

	await _test_game_scene_presentation()
	quit()


## ゲームシーンの演出が進行シグナルと連動することを確認する。
func _test_game_scene_presentation() -> void:
	var game_scene := (
		load("res://scenes/games/game.tscn") as PackedScene
	).instantiate()
	root.add_child(game_scene)
	await process_frame

	var scene_game: MorseGame = game_scene.get_node("MorseGame")
	var scene_input: MorseInput = game_scene.get_node("MorseInput")
	var label: RichTextLabel = game_scene.get_node(
		"PhraseBubble/MarginContainer/VBoxContainer/RichTextLabel"
	)
	var face: TextureRect = game_scene.get_node("NeoUniFace")
	var ufo: Sprite2D = game_scene.get_node("Ufo")

	scene_game.start_phrase("AB")
	assert(label.text.contains("[font_size=72]A[/font_size]"))
	assert(label.text.contains("[color=#808080]B[/color]"))
	assert((ufo.get("_animation") as Tween).is_valid())

	var idle_texture := face.texture
	scene_input.key_pressed.emit()
	assert(face.texture != idle_texture)
	scene_input.key_released.emit(false)
	assert(face.texture == idle_texture)

	scene_input.character_completed.emit(MorseCode.encode("A"), "A")
	await process_frame
	assert(label.text.contains("A[font_size=72]B[/font_size]"))
	scene_input.character_completed.emit(MorseCode.encode("T"), "T")
	var failed_texture := face.texture
	assert(failed_texture != idle_texture)
	scene_input.character_completed.emit(MorseCode.encode("B"), "B")
	assert(face.texture != failed_texture)
	assert((ufo.get("_animation") as Tween).is_valid())
