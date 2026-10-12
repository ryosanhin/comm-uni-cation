extends Node

enum ErrorCode {
	OK,
	EMPTY_PATH,
	RESOURCE_NOT_FOUND,
	ALREADY_LOADING,
	REQUEST_FAILED,
	LOAD_FAILED,
	INVALID_REQUEST,
}


## 読み込み結果と、説明文の生成に必要な補足情報。
class LoadResult extends RefCounted:
	var error_code: ErrorCode = ErrorCode.OK
	var resource: Resource
	var resource_path: String
	var request_error: Error = OK


	## 読み込みに成功したか。
	func is_success() -> bool:
		return error_code == ErrorCode.OK


var _loading_paths: Dictionary[String, bool] = {}


## Resourceをバックグラウンドで読み込み、完了後に結果を返す。[br]
## 同じインスタンスへの同じパスの重複要求は拒否する。読み込み中はツリーに残すこと。[br]
## [param resource_path]: 読み込むリソースのパス[br]
## [param type_hint]: ResourceLoaderへ渡す型のヒント。結果の型を保証するものではない
func load_resource(resource_path: String, type_hint: String = "") -> LoadResult:
	var result := LoadResult.new()
	result.resource_path = resource_path
	if resource_path.is_empty():
		result.error_code = ErrorCode.EMPTY_PATH
		return result

	if not ResourceLoader.exists(resource_path):
		result.error_code = ErrorCode.RESOURCE_NOT_FOUND
		return result

	if _loading_paths.has(resource_path):
		result.error_code = ErrorCode.ALREADY_LOADING
		return result

	var error := ResourceLoader.load_threaded_request(resource_path, type_hint)
	if error != OK:
		result.error_code = ErrorCode.REQUEST_FAILED
		result.request_error = error
		return result

	_loading_paths[resource_path] = true
	while true:
		var status := ResourceLoader.load_threaded_get_status(resource_path)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				result.resource = ResourceLoader.load_threaded_get(resource_path)
				_loading_paths.erase(resource_path)
				if result.resource == null:
					result.error_code = ErrorCode.LOAD_FAILED
				return result
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().process_frame
			_:
				if status == ResourceLoader.THREAD_LOAD_FAILED:
					# 完了済みの失敗要求も回収し、ローダー内部の参照を残さない。
					ResourceLoader.load_threaded_get(resource_path)
				_loading_paths.erase(resource_path)
				result.error_code = (
					ErrorCode.LOAD_FAILED
					if status == ResourceLoader.THREAD_LOAD_FAILED
					else ErrorCode.INVALID_REQUEST
				)
				return result

	return result


## 読み込み結果を人間向けの説明文へ変換する。[br]
## [param result]: 読み込み結果
static func format_error(result: LoadResult) -> String:
	match result.error_code:
		ErrorCode.OK:
			return ""
		ErrorCode.EMPTY_PATH:
			return "リソースパスが指定されていません。"
		ErrorCode.RESOURCE_NOT_FOUND:
			return "リソースが存在しません: %s" % result.resource_path
		ErrorCode.ALREADY_LOADING:
			return "同じパスを読み込み中です: %s" % result.resource_path
		ErrorCode.REQUEST_FAILED:
			return "読み込み要求に失敗しました: %s (%s)" % [result.resource_path, result.request_error]
		ErrorCode.LOAD_FAILED:
			return "リソースの読み込みに失敗しました: %s" % result.resource_path
		ErrorCode.INVALID_REQUEST:
			return "読み込み要求が無効です: %s" % result.resource_path

	return "不明なリソース読み込みエラーです。"
