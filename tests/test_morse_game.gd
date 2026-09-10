extends SceneTree


func _initialize() -> void:
	assert(MorseCode.encode("A") == 0b1_01)
	assert(MorseCode.decode(0b1_01) == "A")
	assert(MorseCode.decode(0b111_111_1) == "")

	var input := MorseInput.new()
	input.name = "MorseInput"
	root.add_child(input)
	var game := MorseGame.new()
	game.name = "MorseGame"
	game.morse_input_path = NodePath("../MorseInput")
	game.start_automatically = false
	root.add_child(game)
	await process_frame

	var counts := [0, 0, 0]
	game.character_succeeded.connect(func(_i: int, _e: String, _c: int) -> void: counts[0] += 1)
	game.character_failed.connect(func(_i: int, _e: String, _a: String, _c: int) -> void: counts[1] += 1)
	game.phrase_succeeded.connect(func(_p: String) -> void: counts[2] += 1)

	game.start_phrase("a b!")
	input.character_completed.emit(MorseCode.encode("T"), "T")
	assert(counts[1] == 1 and game.current_character_index == 0)
	input.character_completed.emit(MorseCode.encode("A"), "A")
	assert(counts[0] == 1 and game.current_character_index == 2)
	input.character_completed.emit(MorseCode.encode("B"), "B")
	assert(counts[2] == 1)
	assert(game.get_accepted_codes() == PackedByteArray([MorseCode.encode("A"), MorseCode.encode("B")]))
	input.character_completed.emit(MorseCode.encode("B"), "B")
	assert(counts[2] == 1)
	quit()
