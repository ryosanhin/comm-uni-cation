class_name MorseGame
extends Node

signal character_succeeded(index: int, expected: String, code: int)
signal character_failed(index: int, expected: String, actual: String, code: int)
signal phrase_succeeded(phrase: String)
signal timed_out
signal remaining_time_changed(seconds: int)

@export var phrase := "HELLO"
@export_range(1.0, 600.0, 1.0, "suffix:s") var time_limit := 30.0
@export var start_automatically := true
@export_node_path("MorseInput") var morse_input_path: NodePath

var remaining_time := 0.0
var current_character_index := 0
var _accepted_codes := PackedByteArray()
var _running := false
var _last_displayed_second := -1
@onready var _morse_input: MorseInput = get_node(morse_input_path)


func _ready() -> void:
	_morse_input.character_completed.connect(_on_character_completed)
	if start_automatically:
		start_phrase(phrase)


func _process(delta: float) -> void:
	if not _running:
		return
	remaining_time = maxf(remaining_time - delta, 0.0)
	var displayed_second := ceili(remaining_time)
	if displayed_second != _last_displayed_second:
		_last_displayed_second = displayed_second
		remaining_time_changed.emit(displayed_second)
	if remaining_time <= 0.0:
		_running = false
		_morse_input.set_input_enabled(false)
		timed_out.emit()


func start_phrase(new_phrase: String) -> void:
	phrase = new_phrase.to_upper()
	current_character_index = 0
	_accepted_codes.clear()
	remaining_time = time_limit
	_last_displayed_second = ceili(remaining_time)
	_morse_input.reset()
	_morse_input.set_input_enabled(true)
	_running = true
	remaining_time_changed.emit(_last_displayed_second)
	_skip_unmapped_characters()
	if current_character_index >= phrase.length():
		_finish_phrase()


func get_accepted_codes() -> PackedByteArray:
	return _accepted_codes.duplicate()


func _on_character_completed(code: int, actual: String) -> void:
	if not _running:
		return
	var expected := phrase.substr(current_character_index, 1)
	if actual == expected:
		var completed_index := current_character_index
		_accepted_codes.append(code)
		current_character_index += 1
		character_succeeded.emit(completed_index, expected, code)
		_skip_unmapped_characters()
		if current_character_index >= phrase.length():
			_finish_phrase()
	else:
		character_failed.emit(current_character_index, expected, actual, code)


func _skip_unmapped_characters() -> void:
	while current_character_index < phrase.length():
		if MorseCode.can_encode(phrase.substr(current_character_index, 1)):
			break
		current_character_index += 1


func _finish_phrase() -> void:
	if not _running:
		return
	_running = false
	_morse_input.set_input_enabled(false)
	phrase_succeeded.emit(phrase)
