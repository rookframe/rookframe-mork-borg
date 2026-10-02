extends Resource

## Local navigation only. A new World application session starts fresh.
var _session := ""
var _actors: Array[Dictionary] = []

func read(session: String, actor: String) -> Dictionary:
	if session != _session:
		_session = session
		_actors = []
	for entry in _actors:
		if str(entry.get("actor", "")) == actor:
			var state: Dictionary = entry.get("state", {})
			return state.duplicate(true)
	return {"chapter": 0, "section": 0, "weapon": "", "pages": {}}

func remember(actor: String, state: Dictionary) -> void:
	var entries: Array[Dictionary] = []
	for entry in _actors:
		if str(entry.get("actor", "")) != actor:
			entries.append(entry)
	entries.append({"actor": actor, "state": state.duplicate(true)})
	_actors = entries
