extends Resource

const TransitionEntry := preload("transition_entry.gd")
const TransitionEnums := preload("transition_enums.gd")

@export var _data_dict: Dictionary[TransitionEnums.Id, TransitionEntry] = {}


func get_transition_data(id: TransitionEnums.Id) -> TransitionEntry:
	if not _data_dict.has(id):
		push_error("TransitionEntryが登録されていません:", id)
		return null
	return _data_dict[id]
