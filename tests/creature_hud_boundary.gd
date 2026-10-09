extends "res://tests/character_hud_boundary.gd"
var preferences := ""
var feedback: Array = []
var tasks: Array = []

func CurrentScene() -> Dictionary:
	return {"ok": true, "value": {"id": "main", "name": "The chapel"}}

func ReadText(_area: String, _path: String) -> Dictionary:
	return {"ok": true, "text": preferences}

func WriteText(_area: String, _path: String, text: String) -> Dictionary:
	preferences = text
	return {"ok": true}

func SelectRook(id: String) -> Dictionary:
	if not rooks.has(id) or actors[rooks[id]].access_level != "Owner":
		return {"ok": false, "message": "Unavailable"}
	selected_rook = id
	hud_actor = rooks[id]
	CharacterHudContextChanged.emit()
	return {"ok": true}

func ShowFeedback(title: String, message: String, _severity: String, _actions: Array) -> int:
	feedback.append([title, message])
	return feedback.size()

func OpenActorTaskWindowWithPresentation(_scene: PackedScene, actor: String, _options: Dictionary, task: Dictionary) -> Dictionary:
	tasks.append({"actor": actor, "task": task.duplicate(true)})
	return {"ok": true}

func OpenActorWindowWithPresentation(_scene: PackedScene, actor: String, _options: Dictionary) -> Dictionary:
	tasks.append({"actor": actor, "sheet": true})
	return {"ok": true}
