extends RefCounted

var _path: String

var _questions: Array[QuestionData] = []


func _init(init_path: String) -> void:
	if not init_path.begins_with("res://"):
		push_error("問題文には \"res://\" から始まるパスを指定してください")
		return

	_path = init_path
	_load_file()


func _load_file() -> void:
	_questions.clear()

	if not FileAccess.file_exists(_path):
		push_warning("問題文ファイル %s が存在しないため、読み込みをスキップします" % _path)
		return

	var file := FileAccess.open(_path, FileAccess.READ)

	if file == null:
		push_error(
				"問題文ファイル %s を開けませんでした: %s"
				% [
						_path,
						FileAccess.get_open_error(),
				]
		)
		return

	_load_csv(file, true)


func _load_csv(csv_file: FileAccess, skip_header: bool) -> void:
	var length := csv_file.get_length()
	var line_number := 1

	# ヘッダー行をここで読み込み
	if skip_header:
		csv_file.get_csv_line()
		line_number += 1

	while csv_file.get_position() < length:
		var elements := csv_file.get_csv_line()
		if not _is_valid_row(elements, line_number):
			line_number += 1
			continue

		_questions.append(
				QuestionData.new(elements[0].strip_edges(), int(elements[1]))
		)
		line_number += 1


func _is_valid_row(elements: PackedStringArray, line_number: int) -> bool:
	if elements.size() != 2:
		push_warning(
				"問題文ファイルの%d行目は列数が2ではないため、スキップします" % line_number
		)
		return false

	if elements[0].strip_edges().is_empty():
		push_warning(
				"問題文ファイルの%d行目は問題文が空のため、スキップします" % line_number
		)
		return false

	if not elements[1].strip_edges().is_valid_int():
		push_warning(
				"問題文ファイルの%d行目は難易度が整数ではないため、スキップします" % line_number
		)
		return false

	return true


## 全部の問題を取得
func get_all_questions() -> PackedStringArray:
	var tmp := _questions.map(
			func(question: QuestionData) -> String:
				return question.text
	)
	
	return PackedStringArray(tmp)


## 全ての問題からランダムに一つ取得
func get_random_question() -> String:
	if _questions.is_empty():
		push_warning(
			"問題が読み込まれていません"
		)
		return ""
	var index := randi_range(0, _questions.size() - 1)
	return _questions[index].text


## 該当する難易度の問題を取得
func get_questions_by_difficulty(difficulty: int) -> PackedStringArray:
	var questions: PackedStringArray = []

	for question: QuestionData in _questions:
		if question.difficulty == difficulty:
			questions.append(question.text)

	return questions

## 該当する難易度の問題からランダムに一つ取得
func get_random_question_by_difficulty(difficulty: int) -> String:
	var candidates := get_questions_by_difficulty(difficulty)

	if candidates.is_empty():
		push_warning(
			"難易度 %d に該当する問題がありません" % difficulty
		)
		return ""
	var index := randi_range(0, candidates.size() - 1)
	return candidates[index]


class QuestionData:
	var text: String
	var difficulty: int


	func _init(
		init_text: String,
		init_difficulty: int,
	) -> void:
		text = init_text
		difficulty = init_difficulty
