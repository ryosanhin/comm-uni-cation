class_name MorseGame
extends Node

const JsonReader := preload("res://questions/json_reader.gd")

const Ufo := preload("res://prefabs/ufo/ufo.gd")

const MorseInput := preload("res://morse/morse_input.gd")

const TimerViewer := preload("res://prefabs/ui/timer_viewer.gd")

const QuestionBubble := preload("res://prefabs/ui/question_bubble.gd")

const QUESTIONS_PATH := "res://questions/questions.json"

## 新しい問題を開始したことを通知する。
signal phrase_started(phrase: String)

## 文字の入力に成功したとき、対象位置・期待した文字・モールス符号を通知する。
signal character_succeeded(index: int, expected: String, code: int)

## 文字の入力に失敗したとき、対象位置・期待値・入力値・モールス符号を通知する。
signal character_failed(index: int, expected: String, actual: String, code: int)

## フレーズ全体の入力に成功したことを通知する。
signal phrase_succeeded(phrase: String)

## 制限時間が切れたことを通知する。
signal timed_out

## 画面に表示する残り秒数が変化したことを通知する。
signal remaining_time_changed(seconds: int)

## プレイヤーが入力する現在の問題文。
@export var phrase := "HELLO"

## フレーズ入力に使用できる制限時間（秒）。
@export_range(1.0, 600.0, 1.0, "suffix:s") var time_limit := 30.0

## ノードの準備完了時に問題ファイルからランダムに出題するかどうか。
@export var start_automatically := true

## 現在の残り時間（秒）。
var remaining_time := 0.0

## 次に入力すべき [member phrase] 内の文字位置。
var current_character_index := 0

## 正解として受理したモールス符号を入力順に保持する。
var _accepted_codes := PackedByteArray()

## フレーズの受付中かどうか。
var _running := false

## UFOの入場が完了し、モールス入力を受け付けているかどうか。
var _accepting_input := false

## JSONファイルから問題を取得するリーダー。
var _question_reader := JsonReader.new(QUESTIONS_PATH)

## 最後に [signal remaining_time_changed] で通知した秒数。
var _last_displayed_second := -1

@export var _morse_input: MorseInput

@export var _ufo: Ufo

@export var _timer_viewer: TimerViewer

## 入力完了シグナルを接続し、設定に応じて最初のフレーズを開始する。
func _ready() -> void:
	_morse_input.character_completed.connect(_on_character_completed)
	if start_automatically:
		start_random_question()


## ゲーム中の残り時間を更新し、表示秒数の変更やタイムアウトを通知する。
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
		_set_input_enabled(false)
		timed_out.emit()


## [param new_phrase] を大文字に正規化し、制限時間と入力状態を初期化してゲームを開始する。
## モールス符号へ変換できない文字は入力対象から除外する。
func start_phrase(new_phrase: String) -> void:
	phrase = new_phrase.to_upper()
	current_character_index = 0
	_accepted_codes.clear()
	remaining_time = time_limit
	_last_displayed_second = ceili(remaining_time)
	_morse_input.reset()
	_set_input_enabled(false)
	_running = true
	remaining_time_changed.emit(_last_displayed_second)
	_skip_unmapped_characters()
	phrase_started.emit(phrase)
	if current_character_index >= phrase.length():
		_finish_phrase()


## 問題ファイルからランダムに1問取得して開始する。
func start_random_question() -> void:
	var question: String = _question_reader.get_random_question()
	if question.is_empty():
		return
	start_phrase(question)


## UFOの入場完了後、進行中の問題に対するモールス入力を受け付ける。
func _on_ufo_entered() -> void:
	if _running:
		_set_input_enabled(true)


## UFOの退場完了時に入力を止め、次の問題を出題する。
func _on_ufo_exited() -> void:
	_set_input_enabled(false)
	start_random_question()


## 正解として受理済みのモールス符号のコピーを返す。
## 戻り値を変更しても内部の記録には影響しない。
func get_accepted_codes() -> PackedByteArray:
	return _accepted_codes.duplicate()


## 1文字分の入力完了を判定し、成功または失敗を通知する。
func _on_character_completed(code: int, actual: String) -> void:
	if not _running or not _accepting_input:
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


## 現在位置から、モールス符号へ変換可能な次の文字まで読み飛ばす。
func _skip_unmapped_characters() -> void:
	while current_character_index < phrase.length():
		if MorseCode.can_encode(phrase.substr(current_character_index, 1)):
			break
		current_character_index += 1


## 入力受付を終了し、フレーズ全体の成功を通知する。
func _finish_phrase() -> void:
	if not _running:
		return
	_running = false
	_set_input_enabled(false)
	phrase_succeeded.emit(phrase)


## モールス入力ノードとゲーム側の入力受付状態を同時に更新する。
func _set_input_enabled(enabled: bool) -> void:
	_accepting_input = enabled
	_morse_input.set_input_enabled(enabled)
