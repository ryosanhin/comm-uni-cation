extends PanelContainer

## 表示対象のゲーム進行ノード。
@export_node_path("MorseGame") var game_path: NodePath

## 現在入力中の文字に適用するフォントサイズ。
@export_range(1, 256, 1, "suffix:px") var current_font_size := 72

## 未入力部分に適用する文字色。
@export var pending_color := Color(0.5, 0.5, 0.5)

@onready var _game: MorseGame = get_node(game_path)
@onready var _label: RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel


## シーン準備時点の問題と進行状況を吹き出しへ反映する。
func _ready() -> void:
	_refresh_from_game()


## 新しい問題文を表示する。
func on_phrase_started(_new_phrase: String) -> void:
	# MorseGame は兄弟ノードより先に ready になるため、初回は _ready に表示を任せる。
	if not is_node_ready():
		return
	_refresh_from_game()


## 正解後、読み飛ばした記号を含む最新位置で表示を更新する。
func advance_character(
	_index: int, _expected: String, _code: int
) -> void:
	call_deferred("_refresh_from_game")


func _refresh_from_game() -> void:
	_render_phrase(_game.phrase, _game.current_character_index)


## 入力済み・入力中・未入力の3領域に分けてBBCodeを組み立てる。
func _render_phrase(phrase: String, current_index: int) -> void:
	var safe_index := clampi(current_index, 0, phrase.length())
	var completed := _escape_bbcode(phrase.left(safe_index))
	var current := ""
	var pending := ""
	if safe_index < phrase.length():
		current = _escape_bbcode(phrase.substr(safe_index, 1))
		pending = _escape_bbcode(phrase.substr(safe_index + 1))

	var color_code := pending_color.to_html(false)
	_label.text = "%s[font_size=%d]%s[/font_size][color=#%s]%s[/color]" % [
		completed, current_font_size, current, color_code, pending
	]


## 問題文をBBCodeとして解釈せず、そのまま表示できるようにする。
func _escape_bbcode(value: String) -> String:
	return value.replace("[", "[lb]")
