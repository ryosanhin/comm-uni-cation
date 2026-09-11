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

## モールス入力を受け付けるかどうか。
var input_enabled := true

## 現在押されている入力元を識別子ごとに保持する。[br]
## Set系の代替として[Dictionary]を使用
var _active_sources: Dictionary[StringName, bool] = {}

## 最初の入力元が押された時刻（ミリ秒）。
var _pressed_at_msec := 0

## 先頭の番兵ビットを含む、入力途中のモールス符号。
var _current_code: int

## 文字間の無入力時間を計測するワンショットタイマー。
var _character_timer: Timer

## ミリ秒を秒に戻す用の値
const MSEC_UNIT := 0.001

## 番兵ビット
const INIT_BIT := 1

## 文字確定用タイマーを生成し、タイムアウト時の処理を接続する。
func _ready() -> void:
	_current_code = INIT_BIT
	_character_timer = Timer.new()
	_character_timer.one_shot = true
	_character_timer.timeout.connect(_complete_character)
	add_child(_character_timer)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		_handle_key(event)

	elif event is InputEventMouseButton:
		_handle_mouse(event)


## 押下中の入力元、計測時刻、入力途中の符号、文字確定タイマーを初期状態へ戻す。
func reset() -> void:
	_active_sources.clear()
	_pressed_at_msec = 0
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


## 入力途中の符号を1文字として確定し、復号結果とともに通知する。[br]
## 符号が空、または入力が無効な場合は何もしない。
func _complete_character() -> void:
	if _current_code == INIT_BIT or not input_enabled:
		return
	var completed_code := _current_code
	_current_code = INIT_BIT
	character_completed.emit(completed_code, MorseCode.decode(completed_code))


## 許可されたキーボードからの入力を処理する。
func _handle_key(event: InputEventKey) -> void:
	if event.echo:
		return

	if not _is_allowed_key(event.keycode):
		return

	var id := StringName("key:%d" % event.keycode)

	if event.pressed:
		_press_input(id)
	else:
		_release_input(id)


## 入力された値が許可範囲内か確認する。
func _is_allowed_key(key: Key) -> bool:
	return (
		(key >= KEY_A and key <= KEY_Z)
		or (key >= KEY_0 and key <= KEY_9)
		or (key >= KEY_KP_0 and key <= KEY_KP_9)
		or key == KEY_SPACE
	)


## マウスからの入力を処理する。[br]
## スクリーンのタッチもマウス入力としてエミュレートしているはずなのでスマホなども対応している？[br]
func _handle_mouse(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	var id := &"mouse:left"

	if event.pressed:
		_press_input(id)
	else:
		_release_input(id)


## 指定したIDの入力が開始したときの処理。[br]
##
func _press_input(id: StringName) -> void:
	if _active_sources.has(id):
		return

	var was_empty := _active_sources.is_empty()
	_active_sources[id] = true

	# 新規入力開始時の処理
	if was_empty:
		_character_timer.stop()
		_pressed_at_msec = Time.get_ticks_msec()
		key_pressed.emit()


## 指定したIDの入力が終了したときの処理。[br]
## [param id]: 入力種を一意に表す[StringName]
func _release_input(id: StringName) -> void:
	if not _active_sources.has(id):
		return

	_active_sources.erase(id)

	# 全ての入力が無くなったときの処理
	if _active_sources.is_empty():
		var duration := float(Time.get_ticks_msec() - _pressed_at_msec) * MSEC_UNIT
		var is_dash := duration >= dash_threshold
		_current_code = (_current_code << 1) | int(is_dash)
		key_released.emit(duration, is_dash)
		_character_timer.start(character_gap)
