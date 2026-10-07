class_name MorseGame
extends Node

const QuestionLoader := preload("res://questions/question_loader.gd")

const Ufo := preload("res://prefabs/ufo/ufo.gd")

const TimerViewer := preload("res://prefabs/ui/timer_viewer.gd")

const QuestionBubble := preload("res://prefabs/ui/question_bubble.gd")

const NeoUniFace := preload("res://prefabs/ui/neo_uni_face.gd")

const MorsePreview := preload("res://prefabs/ui/morse_preview.gd")

const GameTimer := preload("res://prefabs/game_timer.gd")

const CountDownAnimation := preload("res://prefabs/ui/count_down_animation.gd")

const ResultPanel := preload("res://prefabs/ui/result_panel.gd")

const QUESTIONS_PATH := "res://questions/questions.csv"

## 新しい問題を開始したことを通知する。
signal question_started(question: String)

## 文字の入力に成功したとき、対象位置・期待した文字・モールス符号を通知する。
signal character_succeeded(index: int, expected: String, code: int)

## 文字の入力に失敗したとき、対象位置・期待値・入力値・モールス符号を通知する。
signal character_failed(index: int, expected: String, actual: String, code: int)

## フレーズ全体の入力に成功したことを通知する。
signal question_succeeded(question: String)

## プレイヤーが入力する現在の問題文。
@export var _question := "HELLO"

## ノードの準備完了時に問題ファイルからランダムに出題するかどうか。
@export var start_automatically := true

## 次に入力すべき [member _question] 内の文字位置。
var _current_character_index := 0

## 正解として受理したモールス符号を入力順に保持する。
var _accepted_codes := PackedByteArray()

## フレーズの受付中かどうか。
var _running := false

## UFOの入場が完了し、モールス入力を受け付けているかどうか。
var _accepting_input := false

## 制限時間を迎え、ゲームが終了したかどうか。
var _game_finished := false

## 交信に成功したUFOの数。
var _completed_question_count := 0

## JSONファイルから問題を取得するリーダー。
var _question_loader := QuestionLoader.new(QUESTIONS_PATH)

@export var _morse_input: MorseInput

@export var _ufo: Ufo

@export var _neo_uni_face: NeoUniFace

@export var _question_bubble: QuestionBubble

@export var _morse_preview: MorsePreview

@export var _timer_viewer: TimerViewer

@export var _game_timer: GameTimer

@export var _count_down_animation: CountDownAnimation

@export var _finish_animation: CountDownAnimation

@export var _result_panel: ResultPanel


## ゲーム画面のシグナルを接続し、開始演出が終了してからゲームを開始する。
func _ready() -> void:
	_connect_game_signals()
	_connect_input_signals()
	_connect_ufo_signals()
	_connect_timer_signals()
	_set_input_enabled(false)

	if start_automatically:
		if not _count_down_animation.is_node_ready():
			await _count_down_animation.ready
		await _count_down_animation.animation_async()
		start_random_question()
		_game_timer.start()


## ゲーム進行シグナルを、対応する画面演出へ接続する。
func _connect_game_signals() -> void:
	question_started.connect(_neo_uni_face.set_idle_expression)
	question_started.connect(_question_bubble.on_phrase_started)
	question_started.connect(_ufo.enter_anima)

	character_succeeded.connect(_question_bubble.advance_character)
	
	character_failed.connect(_neo_uni_face.set_failed_expression)
	
	question_succeeded.connect(_neo_uni_face.set_succeeded_expression)
	question_succeeded.connect(_ufo.exit_anima)


## モールス入力シグナルを、ゲーム進行と入力中の画面演出へ接続する。
func _connect_input_signals() -> void:
	_morse_input.character_completed.connect(_on_character_completed)
	_morse_input.character_completed.connect(_morse_preview.clear)
	
	_morse_input.dash_threshold_reached.connect(_morse_preview.change_to_dash)
	
	_morse_input.key_pressed.connect(_neo_uni_face.set_pressed_expression)
	_morse_input.key_pressed.connect(_morse_preview.append_dot)
	
	_morse_input.key_released.connect(_neo_uni_face.set_released_expression)


## UFOの入退場完了シグナルをゲーム進行へ接続する。
func _connect_ufo_signals() -> void:
	_ufo.entered.connect(_on_ufo_entered)

	_ufo.exited.connect(_on_ufo_exited)


## ゲーム内タイマーとのシグナル接続。
func _connect_timer_signals() -> void:
	_game_timer.remained_rate_changed.connect(_timer_viewer.update_progress)

	_game_timer.timeout.connect(_on_timed_out)


## 問題文を大文字に正規化し、制限時間と入力状態を初期化してゲームを開始する。
## モールス符号へ変換できない文字は入力対象から除外する。
func start_phrase(new_question: String) -> void:
	_question = new_question.to_upper()

	_current_character_index = 0
	
	_accepted_codes.clear()
	
	_morse_input.reset()

	_set_input_enabled(false)

	_running = true
	
	_skip_unmapped_characters()
	
	question_started.emit(_question)

	if _current_character_index >= _question.length():
		_finish_phrase()


## 問題ファイルからランダムに1問取得して開始する。
func start_random_question() -> void:
	var question := _question_loader.get_random_question()
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
	if _game_finished:
		return
	start_random_question()


## 入力を停止し、終了演出が完了してからリザルトを表示する。
func _on_timed_out() -> void:
	if _game_finished:
		return
	_game_finished = true
	_running = false
	_set_input_enabled(false)
	_morse_preview.clear(0, "")
	await _finish_animation.animation_async()
	_result_panel.show_result(_completed_question_count)


## 正解として受理済みのモールス符号のコピーを返す。
## 戻り値を変更しても内部の記録には影響しない。
func get_accepted_codes() -> PackedByteArray:
	return _accepted_codes.duplicate()


## 1文字分の入力完了を判定し、成功または失敗を通知する。
func _on_character_completed(code: int, actual: String) -> void:
	if not _running or not _accepting_input:
		return
	var expected := _question.substr(_current_character_index, 1)
	if actual == expected:
		var completed_index := _current_character_index
		_accepted_codes.append(code)
		_current_character_index += 1
		character_succeeded.emit(completed_index, expected, code)
		_skip_unmapped_characters()
		if _current_character_index >= _question.length():
			_finish_phrase()
	else:
		character_failed.emit(_current_character_index, expected, actual, code)


## 現在位置から、モールス符号へ変換可能な次の文字まで読み飛ばす。
func _skip_unmapped_characters() -> void:
	while _current_character_index < _question.length():
		if MorseCode.can_encode(_question.substr(_current_character_index, 1)):
			break
		_current_character_index += 1


## 入力受付を終了し、フレーズ全体の成功を通知する。
func _finish_phrase() -> void:
	if not _running:
		return
	_running = false
	_set_input_enabled(false)
	_completed_question_count += 1
	question_succeeded.emit(_question)


## モールス入力ノードとゲーム側の入力受付状態を同時に更新する。
func _set_input_enabled(enabled: bool) -> void:
	_accepting_input = enabled
	_morse_input.set_input_enabled(enabled)
