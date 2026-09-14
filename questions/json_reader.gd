extends RefCounted

var _path: String

var _questions: Array[QuestionData] = []


func _init(init_path: String) -> void:
	if not init_path.begins_with("res://"):
		push_error("問題文には \"res://\" から始まるパスを指定してください")
	else:
		_path = init_path
	_load_file()


func _load_file() -> void:
	_questions.clear()

	var file := FileAccess.open(_path, FileAccess.READ)

	if file == null:
		push_error("問題文ファイルを開けませんでした: %s" % _path)
		return

	var json_text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(json_text)

	if parsed == null:
		push_error("JSONの解析に失敗しました: %s" % _path)
		return

	if not parsed is Array:
		push_error("JSONのルートは配列である必要があります")
		return
	
	for item: Variant in parsed:
		if not item is Dictionary:
			push_warning("Dictionaryではないデータを無視しました")
			continue

		var data: Dictionary = item

		if not data.has("question") or not data.has("difficulty"):
			push_warning("必要な項目がないデータを無視しました")
			continue

		if not data["question"] is String:
			push_warning("textがStringではないデータを無視しました")
			continue

		# String.to_float() を利用してパースしているらしいのでflaotで受ける
		if not data["difficulty"] is float:
			push_warning("difficultyが数値ではないデータを無視しました")
			continue

		var question := QuestionData.new(
				data["question"].to_upper(),
				int(data["difficulty"])
		)

		_questions.append(question)


func get_questions_by_difficulty(difficulty: int) -> PackedStringArray:
	var questions: PackedStringArray = []

	for question: QuestionData in _questions:
		if question.difficulty == difficulty:
			questions.append(question.text)

	return questions


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
