extends Resource
class_name TransitionDatabase

@export var _data_dict: Dictionary[TransitionEnums.Id, TransitionData] = {}

func get_transition_data(id: TransitionEnums.Id) -> TransitionData:
	if not _data_dict.has(id):
		push_error("TransitionDataが登録されていません:", id)
		return null
	return _data_dict[id]
