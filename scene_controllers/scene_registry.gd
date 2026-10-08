extends Resource
class_name SceneRegistry

@export var _data_dict: Dictionary[SceneEnums.Id, SceneEntry] = {}


func get_scene_data(id: SceneEnums.Id) -> SceneEntry:
	if not _data_dict.has(id):
		push_error("SceneEntryが登録されていません: %s" % id)
		return null

	return _data_dict[id]
