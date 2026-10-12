extends Node

var _loading_paths: Dictionary[String, bool] = {}


## Resourceをバックグラウンドで読み込み、完了後に返す。失敗時はnullを返す。[br]
## 同じインスタンスへの同じパスの重複要求は拒否する。読み込み中はツリーに残すこと。[br]
## [param resource_path]: 読み込むリソースのパス[br]
## [param type_hint]: ResourceLoaderへ渡す型のヒント。結果の型を保証するものではない
func load_resource(resource_path: String, type_hint: String = "") -> Resource:
	if resource_path.is_empty() or not ResourceLoader.exists(resource_path):
		push_error("リソースが存在しません: %s" % resource_path)
		return null

	if _loading_paths.has(resource_path):
		push_error("同じパスを読み込み中です: %s" % resource_path)
		return null

	var error := ResourceLoader.load_threaded_request(resource_path, type_hint)
	if error != OK:
		push_error("読み込み要求に失敗しました: %s (%s)" % [resource_path, error])
		return null

	_loading_paths[resource_path] = true
	while true:
		var status := ResourceLoader.load_threaded_get_status(resource_path)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				var resource := ResourceLoader.load_threaded_get(resource_path)
				_loading_paths.erase(resource_path)
				return resource
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				await get_tree().process_frame
			_:
				if status == ResourceLoader.THREAD_LOAD_FAILED:
					# 完了済みの失敗要求も回収し、ローダー内部の参照を残さない。
					ResourceLoader.load_threaded_get(resource_path)
				_loading_paths.erase(resource_path)
				push_error("リソースの読み込みに失敗しました: %s" % resource_path)
				return null

	return null
