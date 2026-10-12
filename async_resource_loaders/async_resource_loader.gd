extends RefCounted

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
	## 呼び出し元が指定したUIDまたはパス。エラー説明に利用する。
	var resource_path: String
	var request_error: Error = OK


	## 読み込みに成功したか。
	func is_success() -> bool:
		return error_code == ErrorCode.OK


var _check_requested: Signal
var _loading_paths: Dictionary[String, bool] = {}


## 読み込み状況の再確認を知らせるシグナルを設定する。[br]
## [param init_check_requested]: 読み込み中も繰り返し発火する有効なシグナル。
## シグナルの発行元は、読み込みが完了するまで維持すること。
func _init(init_check_requested: Signal) -> void:
	_check_requested = init_check_requested


## Resourceをバックグラウンドで読み込み、完了後に結果を返す。[br]
## 同じインスタンスへの同じリソースの重複要求は、UIDとパスの違いにかかわらず拒否する。[br]
## [param resource_reference]: 読み込むリソースのUID。通常のリソースパスも指定できる[br]
## [param type_hint]: ResourceLoaderへ渡す型のヒント。結果の型を保証するものではない
func load_resource_async(resource_reference: String, type_hint: String = "") -> LoadResult:
	var result := LoadResult.new()
	result.resource_path = resource_reference
	if resource_reference.is_empty():
		result.error_code = ErrorCode.EMPTY_PATH
		return result

	var resource_path := resolve_resource_path(resource_reference)
	if resource_path.is_empty() or not ResourceLoader.exists(resource_path):
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
				await _check_requested
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


## UIDを現在のリソースパスへ解決する。通常のパスは整理して返す。[br]
## 解決できないUIDでは空文字列を返し、リソース自体は読み込まない。[br]
## [param resource_reference]: リソースのUIDまたはパス
static func resolve_resource_path(resource_reference: String) -> String:
	if resource_reference.is_empty():
		return ""
	if resource_reference.begins_with("uid://"):
		var uid := ResourceUID.text_to_id(resource_reference)
		if uid == ResourceUID.INVALID_ID or not ResourceUID.has_id(uid):
			return ""
		return ResourceUID.get_id_path(uid).simplify_path()

	if resource_reference.is_relative_path():
		return ("res://" + resource_reference).simplify_path()
	return resource_reference.simplify_path()


## 読み込み結果を人間向けの説明文へ変換する。[br]
## [param result]: 読み込み結果
static func format_error(result: LoadResult) -> String:
	match result.error_code:
		ErrorCode.OK:
			return ""
		ErrorCode.EMPTY_PATH:
			return "リソースのUIDまたはパスが指定されていません。"
		ErrorCode.RESOURCE_NOT_FOUND:
			return "リソースが存在しません: %s" % result.resource_path
		ErrorCode.ALREADY_LOADING:
			return "同じリソースを読み込み中です: %s" % result.resource_path
		ErrorCode.REQUEST_FAILED:
			return "読み込み要求に失敗しました: %s (%s)" % [result.resource_path, result.request_error]
		ErrorCode.LOAD_FAILED:
			return "リソースの読み込みに失敗しました: %s" % result.resource_path
		ErrorCode.INVALID_REQUEST:
			return "読み込み要求が無効です: %s" % result.resource_path

	return "不明なリソース読み込みエラーです。"
