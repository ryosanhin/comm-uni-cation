extends Control

@export var bubble_texture: Texture2D:
	set(value):
		bubble_texture = value
		if is_node_ready():
			%bubble.texture = value
@export var tail_texture: Texture2D:
	set(value):
		tail_texture = value
		if is_node_ready():
			%Tail.texture = value
@export var key_handle_texture: Texture2D:
	set(value):
		key_handle_texture = value
		if is_node_ready():
			%KeyHandle.texture = value

@onready var game: MorseGame = $MorseGame


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


func _on_remaining_time_changed(seconds: int) -> void:
	%TimeLabel.text = "TIME %d" % seconds


func _on_character_succeeded(index: int, _expected: String, _code: int) -> void:
	%StatusLabel.text = "OK  %d / %d" % [index + 1, game.phrase.length()]


func _on_character_failed(_index: int, expected: String, _actual: String, _code: int) -> void:
	%StatusLabel.text = "TRY AGAIN: %s" % expected


func _on_phrase_succeeded(_phrase: String) -> void:
	%StatusLabel.text = "SUCCESS!"
	%KeyHandle.position.y = 0.0


func _on_timed_out() -> void:
	%StatusLabel.text = "TIME UP"
	%KeyHandle.position.y = 0.0


func _on_key_pressed() -> void:
	%KeyHandle.position.y = 8.0


func _on_key_released(_duration: float, _is_dash: bool) -> void:
	%KeyHandle.position.y = 0.0
