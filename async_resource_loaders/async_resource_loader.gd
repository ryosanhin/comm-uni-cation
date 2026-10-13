extends RefCounted

enum ErrorCode {
	OK,
	EMPTY_PATH,
	RESOURCE_NOT_FOUND,
	REQUEST_FAILED,
	LOAD_FAILED,
	INVALID_REQUEST,
}


## 1件の読み込み処理と、その完了状態・結果。
class LoadRequest extends RefCounted:
	## 成功・失敗にかかわらず、結果を確定した後に一度だけ通知する。
	signal completed

	var error_code: ErrorCode = ErrorCode.OK
	var resource: Resource
	## 呼び出し元が指定したUIDまたはパス。エラー説明に利用する。
	var resource_path: String
	var request_error: Error = OK

	var _is_completed := false


	## 読み込みが成功または失敗で完了したか。
	func is_completed() -> bool:
		return _is_completed


	## 読み込みが完了し、成功したか。
	func is_success() -> bool:
		return _is_completed and error_code == ErrorCode.OK


	## Resourceをバックグラウンドで読み込み、結果を確定する。[br]
	## リクエスト生成時に一度だけ呼び出す。[br]
	## [param resolved_path]: UIDまたはパスから解決した読み込み先[br]
	## [param type_hint]: ResourceLoaderへ渡す型のヒント[br]
	## [param check_requested]: 読み込み状況の再確認を知らせるシグナル
	func _load_resource_async(
		resolved_path: String,
		type_hint: String,
		check_requested: Signal
	) -> void:
		if resource_path.is_empty():
			error_code = ErrorCode.EMPTY_PATH
			_complete()
			return

		if resolved_path.is_empty() or not ResourceLoader.exists(resolved_path):
			error_code = ErrorCode.RESOURCE_NOT_FOUND
			_complete()
			return

		request_error = ResourceLoader.load_threaded_request(resolved_path, type_hint)
		if request_error != OK:
			error_code = ErrorCode.REQUEST_FAILED
			_complete()
			return

		while true:
			var status := ResourceLoader.load_threaded_get_status(resolved_path)
			match status:
				ResourceLoader.THREAD_LOAD_LOADED:
					resource = ResourceLoader.load_threaded_get(resolved_path)
					if resource == null:
						error_code = ErrorCode.LOAD_FAILED
					_complete()
					return
				ResourceLoader.THREAD_LOAD_IN_PROGRESS:
					await check_requested
				_:
					if status == ResourceLoader.THREAD_LOAD_FAILED:
						# 完了済みの失敗要求も回収し、ローダー内部の参照を残さない。
						ResourceLoader.load_threaded_get(resolved_path)
					error_code = (
						ErrorCode.LOAD_FAILED
						if status == ResourceLoader.THREAD_LOAD_FAILED
						else ErrorCode.INVALID_REQUEST
					)
					_complete()
					return


	## 結果を確定し、完了を通知する。
	func _complete() -> void:
		_is_completed = true
		completed.emit()


var _check_requested: Signal


## 読み込み状況の再確認を知らせるシグナルを設定する。[br]
## [param init_check_requested]: 読み込み中も繰り返し発火する有効なシグナル。
## シグナルの発行元は、読み込みが完了するまで維持すること。
func _init(init_check_requested: Signal) -> void:
	_check_requested = init_check_requested


## 1件のリクエストを生成し、読み込みを開始して直ちに返す。[br]
## すでに完了している場合もあるため、待機前にis_completed()を確認する。[br]
## [param resource_reference]: 読み込むリソースのUID。通常のリソースパスも指定できる[br]
## [param type_hint]: ResourceLoaderへ渡す型のヒント。結果の型を保証するものではない
func create_request(resource_reference: String, type_hint: String = "") -> LoadRequest:
	var request := LoadRequest.new()
	request.resource_path = resource_reference
	request._load_resource_async(
		resolve_resource_path(resource_reference), type_hint, _check_requested
	)
	return request


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
## [param request]: 読み込み結果
static func format_error(request: LoadRequest) -> String:
	match request.error_code:
		ErrorCode.OK:
			return ""
		ErrorCode.EMPTY_PATH:
			return "リソースのUIDまたはパスが指定されていません。"
		ErrorCode.RESOURCE_NOT_FOUND:
			return "リソースが存在しません: %s" % request.resource_path
		ErrorCode.REQUEST_FAILED:
			return "読み込み要求に失敗しました: %s (%s)" % [request.resource_path, request.request_error]
		ErrorCode.LOAD_FAILED:
			return "リソースの読み込みに失敗しました: %s" % request.resource_path
		ErrorCode.INVALID_REQUEST:
			return "読み込み要求が無効です: %s" % request.resource_path

	return "不明なリソース読み込みエラーです。"

