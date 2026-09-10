class_name MorseInput
extends Node

signal key_pressed
signal key_released(duration_seconds: float, is_dash: bool)
signal character_completed(code: int, character: String)

@export_range(0.05, 2.0, 0.01, "suffix:s") var dash_threshold := 0.25
@export_range(0.05, 2.0, 0.01, "suffix:s") var character_gap := 0.45
@export var input_action: StringName = &"morse_key"

var input_enabled := true
var _active_sources: Dictionary[String, bool] = {}
var _pressed_at_usec := 0
var _current_code := 1
var _character_timer: Timer


func _ready() -> void:
	_character_timer = Timer.new()
	_character_timer.one_shot = true
	_character_timer.timeout.connect(_complete_character)
	add_child(_character_timer)


func _input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventScreenTouch:
		_set_source("touch:%d" % event.index, event.pressed)
		get_viewport().set_input_as_handled()
	elif event.is_action(input_action):
		if event is InputEventKey and event.echo:
			return
		_set_source(_source_id(event), event.is_pressed())
		get_viewport().set_input_as_handled()


func reset() -> void:
	_active_sources.clear()
	_pressed_at_usec = 0
	_current_code = 1
	if is_instance_valid(_character_timer):
		_character_timer.stop()


func set_input_enabled(value: bool) -> void:
	input_enabled = value
	if not value:
		reset()


func _set_source(source: String, pressed: bool) -> void:
	var was_pressed := not _active_sources.is_empty()
	if pressed:
		_active_sources[source] = true
	else:
		_active_sources.erase(source)
	var is_pressed := not _active_sources.is_empty()
	if not was_pressed and is_pressed:
		_character_timer.stop()
		_pressed_at_usec = Time.get_ticks_usec()
		key_pressed.emit()
	elif was_pressed and not is_pressed:
		var duration := float(Time.get_ticks_usec() - _pressed_at_usec) / 1_000_000.0
		var is_dash := duration >= dash_threshold
		_current_code = (_current_code << 1) | int(is_dash)
		key_released.emit(duration, is_dash)
		_character_timer.start(character_gap)


func _source_id(event: InputEvent) -> String:
	if event is InputEventKey:
		return "key:%d:%d" % [event.device, event.physical_keycode]
	if event is InputEventMouseButton:
		return "mouse:%d:%d" % [event.device, event.button_index]
	return "action:%d" % event.device


func _complete_character() -> void:
	if _current_code == 1 or not input_enabled:
		return
	var completed_code := _current_code
	_current_code = 1
	character_completed.emit(completed_code, MorseCode.decode(completed_code))
