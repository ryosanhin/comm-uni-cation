extends TextureRect

@export var _idle_texture: Texture2D
@export var _pressed_texture: Texture2D
@export var _success_texture: Texture2D
@export var _failed_texture: Texture2D


func _switch_to_idle() -> void:
	texture = _idle_texture


func _switch_to_pressed() -> void:
	texture = _pressed_texture


func _switch_to_success() -> void:
	texture = _success_texture


func _switch_to_failed() -> void:
	texture = _failed_texture


## 問題開始時は通常の表情に戻す。
func _on_phrase_started(_phrase: String) -> void:
	_switch_to_idle()


## モールスキーを押している間は入力中の表情にする。
func _on_key_pressed() -> void:
	_switch_to_pressed()


## モールスキーを離したら通常の表情に戻す。
func _on_key_released(_is_dash: bool) -> void:
	_switch_to_idle()


## 1文字の入力ミスを失敗の表情で知らせる。
func _on_character_failed(
	_index: int, _expected: String, _actual: String, _code: int
) -> void:
	_switch_to_failed()


## 問題への正解を成功の表情で知らせる。
func _on_phrase_succeeded(_phrase: String) -> void:
	_switch_to_success()
