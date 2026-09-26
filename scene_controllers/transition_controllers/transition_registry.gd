extends Resource

const TransitionEnums := preload("transition_enums.gd")

@export var _entries: Dictionary[TransitionEnums.Id, TransitionEntry] = {}


func get_entry(id: TransitionEnums.Id) -> TransitionEntry:
	if not _entries.has(id):
		push_error("TransitionEntryが登録されていません:", id)
		return null
	return _entries[id]
