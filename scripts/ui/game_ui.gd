extends Control

## 吹き出し本体に表示するテクスチャ。ノード準備後の変更は即座に表示へ反映する。
@export var bubble_texture: Texture2D:
	set(value):
		bubble_texture = value
		if is_node_ready():
			%bubble.texture = value
## 吹き出しのしっぽに表示するテクスチャ。ノード準備後の変更は即座に表示へ反映する。
@export var tail_texture: Texture2D:
	set(value):
		tail_texture = value
		if is_node_ready():
			%Tail.texture = value
## モールスキーのハンドルに表示するテクスチャ。ノード準備後の変更は即座に表示へ反映する。
@export var key_handle_texture: Texture2D:
	set(value):
		key_handle_texture = value
		if is_node_ready():
			%KeyHandle.texture = value

## 進行状況と制限時間を管理する [MorseGame] ノード。
@onready var game: MorseGame = $MorseGame


## テクスチャと初期フレーズを画面へ反映し、ゲームおよび入力のシグナルを接続する。
func _ready() -> void:
	%Bubble.texture = bubble_texture
	%Tail.texture = tail_texture
	%KeyHandle.texture = key_handle_texture
	%PhraseLabel.text = game.phrase
	game.remaining_time_changed.connect(_on_remaining_time_changed)
	game.character_succeeded.connect(_on_character_succeeded)
	game.character_failed.connect(_on_character_failed)
	game.phrase_succeeded.connect(_on_phrase_succeeded)
	game.timed_out.connect(_on_timed_out)
	$MorseInput.key_pressed.connect(_on_key_pressed)
	$MorseInput.key_released.connect(_on_key_released)


## 残り時間の表示を [param seconds] 秒に更新する。
func _on_remaining_time_changed(seconds: int) -> void:
	%TimeLabel.text = "TIME %d" % seconds


## 正解した文字数を進捗表示へ反映する。
func _on_character_succeeded(index: int, _expected: String, _code: int) -> void:
	%StatusLabel.text = "OK  %d / %d" % [index + 1, game.phrase.length()]


## 入力失敗を通知し、次に期待する [param expected] を表示する。
func _on_character_failed(_index: int, expected: String, _actual: String, _code: int) -> void:
	%StatusLabel.text = "TRY AGAIN: %s" % expected


## フレーズ成功を表示し、モールスキーのハンドルを通常位置へ戻す。
func _on_phrase_succeeded(_phrase: String) -> void:
	%StatusLabel.text = "SUCCESS!"
	%KeyHandle.position.y = 0.0


## タイムアップを表示し、モールスキーのハンドルを通常位置へ戻す。
func _on_timed_out() -> void:
	%StatusLabel.text = "TIME UP"
	%KeyHandle.position.y = 0.0


## モールスキーの押下に合わせてハンドルを押し下げた位置へ移動する。
func _on_key_pressed() -> void:
	%KeyHandle.position.y = 8.0


## モールスキーの解放に合わせてハンドルを通常位置へ戻す。
func _on_key_released(_duration: float, _is_dash: bool) -> void:
	%KeyHandle.position.y = 0.0
