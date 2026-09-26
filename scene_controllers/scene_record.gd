extends Resource

const SceneEntry := preload("scene_entry.gd")
const SceneEnums := preload("scene_enums.gd")

@export var _data_dict: Dictionary[SceneEnums.Id, SceneData] = {}


func get_scene_data(id: SceneEnums.Id) -> SceneData:
	if not _data_dict.has(id):
		push_error("SceneDataが登録されていません: %s" % id)
		return null

	return _data_dict[id]
