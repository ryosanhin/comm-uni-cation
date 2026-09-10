class_name MorseInput
extends Node

## いずれかの入力元でモールスキーが押されたことを通知する。
signal key_pressed
## モールスキーが離されたとき、押下時間と長点判定を通知する。
signal key_released(duration_seconds: float, is_dash: bool)
## 文字間の待機時間が経過し、1文字分の符号が確定したことを通知する。
signal character_completed(code: int, character: String)

## この秒数以上の押下を長点として判定するしきい値。
@export_range(0.05, 2.0, 0.01, "suffix:s") var dash_threshold := 0.25
## キーを離してから1文字分の入力を確定するまでの待機時間（秒）。
@export_range(0.05, 2.0, 0.01, "suffix:s") var character_gap := 0.45
## キーボードやマウス入力に使用する InputMap のアクション名。
@export var input_action: StringName = &"morse_key"

## モールス入力を受け付けるかどうか。
var input_enabled := true
## 現在押されている入力元を識別子ごとに保持する。
var _active_sources: Dictionary[String, bool] = {}
## 最初の入力元が押された時刻（マイクロ秒）。
var _pressed_at_usec := 0
## 先頭の番兵ビットを含む、入力途中のモールス符号。
var _current_code := 1
## 文字間の無入力時間を計測するワンショットタイマー。
var _character_timer: Timer


## 文字確定用タイマーを生成し、タイムアウト時の処理を接続する。
func _ready() -> void:
	_character_timer = Timer.new()
	_character_timer.one_shot = true
	_character_timer.timeout.connect(_complete_character)
	add_child(_character_timer)


## タッチまたは [member input_action] の入力状態を入力元ごとに処理する。[br]
## キーリピートは無視し、処理したイベントを入力済みとしてマークする。
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


## 押下中の入力元、計測時刻、入力途中の符号、文字確定タイマーを初期状態へ戻す。
func reset() -> void:
	_active_sources.clear()
	_pressed_at_usec = 0
	_current_code = 1
	if is_instance_valid(_character_timer):
		_character_timer.stop()


## 入力受付状態をに変更する。[br]
## 無効化する場合は入力途中の状態もリセットする。[br]
## [param value]: 変更先
func set_input_enabled(value: bool) -> void:
	input_enabled = value
	if not value:
		reset()


## 指定された入力種の押下状態を更新し、全入力元をまとめた押下開始・終了を処理する。[br]
## 押下終了時は押下時間から短点または長点を判定し、文字確定タイマーを開始する。[br]
## [param source]: 入力種[br]
## [param pressed]: 押されているか
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


## 入力イベントの種類・デバイス・キーまたはボタンから入力元の識別子を作る。
func _source_id(event: InputEvent) -> String:
	if event is InputEventKey:
		return "key:%d:%d" % [event.device, event.physical_keycode]
	if event is InputEventMouseButton:
		return "mouse:%d:%d" % [event.device, event.button_index]
	return "action:%d" % event.device


## 入力途中の符号を1文字として確定し、復号結果とともに通知する。[br]
## 符号が空、または入力が無効な場合は何もしない。
func _complete_character() -> void:
	if _current_code == 1 or not input_enabled:
		return
	var completed_code := _current_code
	_current_code = 1
	character_completed.emit(completed_code, MorseCode.decode(completed_code))
