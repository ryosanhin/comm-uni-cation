extends SceneTree
## jsonを正しく読めるかテスト

const QuestionLoader := preload("res://questions/question_loader.gd")


const CSV_PATH := "res://tests/question_loader/test.csv"
const INVALID_CSV_PATH := "res://tests/question_loader/invalid_test.csv"
const NOT_FOUND_CSV_PATH := "res://tests/question_loader/not_found.csv"


func _init() -> void:
	var runner := TestRunner.new(true)

	runner.change_test_name("csv read test")

	var question_loader := QuestionLoader.new(CSV_PATH)

	var level_1_questions := question_loader.get_questions_by_difficulty(1)
	runner.assert_equal(level_1_questions.size(), 2, "読み込み数が一致することを確認")
	runner.assert_equal(level_1_questions[0], "test", "test: 値が一致することを確認")
	runner.assert_equal(level_1_questions[1], "hoge", "hoge: 値が一致することを確認")

	var level_2_questions := question_loader.get_questions_by_difficulty(2)
	runner.assert_equal(level_2_questions.size(), 1, "読み込み数が一致することを確認")
	runner.assert_equal(level_2_questions[0], "fuga", "fuga: 値が一致することを確認")


	var level_3_questions := question_loader.get_questions_by_difficulty(3)
	runner.assert_equal(level_3_questions.size(), 1, "読み込み数が一致することを確認")
	runner.assert_equal(level_3_questions[0], "piyo", "piyo: 値が一致することを確認")

	runner.change_test_name("invalid csv row skip test")

	var invalid_question_loader := QuestionLoader.new(INVALID_CSV_PATH)
	runner.assert_array(
			invalid_question_loader.get_all_questions(),
			["valid", "also valid"],
			"不正な列数・空の問題文・整数ではない難易度の行をスキップすることを確認",
	)

	runner.change_test_name("missing csv test")

	var missing_question_loader := QuestionLoader.new(NOT_FOUND_CSV_PATH)
	runner.assert_array(
			missing_question_loader.get_all_questions(),
			[],
			"存在しないファイルでも空の問題一覧を返して終了することを確認",
	)

	await runner.finish(self, "QuestionLoader")
