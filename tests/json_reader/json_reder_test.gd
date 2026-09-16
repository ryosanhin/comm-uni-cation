extends SceneTree
## jsonを正しく読めるかテスト

const QuestionLoader := preload("res://questions/question_loader.gd")


const JSON_PATH := "res://tests/json_reader/test.json"


func _init() -> void:
	var runner := TestRunner.new(true)

	runner.change_test_name("json read test")

	var question_loader := QuestionLoader.new(JSON_PATH)

	var level_1_questions := question_loader.get_questions_by_difficulty(1)
	runner.assert_equal(level_1_questions.size(), 2, "読み込み数が一致することを確認")
	runner.assert_equal(level_1_questions[0], "TEST", "TEST: 値が一致することを確認")
	runner.assert_equal(level_1_questions[1], "HOGE", "HOGE: 値が一致することを確認")

	var level_2_questions := question_loader.get_questions_by_difficulty(2)
	runner.assert_equal(level_2_questions.size(), 1, "読み込み数が一致することを確認")
	runner.assert_equal(level_2_questions[0], "FUGA", "FUGA: 値が一致することを確認")


	var level_3_questions := question_loader.get_questions_by_difficulty(3)
	runner.assert_equal(level_3_questions.size(), 1, "読み込み数が一致することを確認")
	runner.assert_equal(level_3_questions[0], "PIYO", "PIYO: 値が一致することを確認")

	await runner.finish(self, "QuestionLoader")
