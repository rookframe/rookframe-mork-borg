extends "res://tests/power_composition_boundary.gd"
var world_data: Variant = {"unrelated": "retained"}

func ReadWorldData() -> Dictionary:
	return {"ok": true, "value": world_data.duplicate(true)}

func SystemIntentReadWorldData(_token: String) -> Dictionary:
	return ReadWorldData()

func SystemIntentCommitWorldData(_token: String, value: Variant, report: Dictionary) -> Dictionary:
	if fail_commit:
		return {"ok": false, "message": "Save failed"}
	world_data = value.duplicate(true)
	if not report.is_empty():
		reports.append(report.duplicate(true))
	WorldChanged.emit()
	return {"ok": true}

func ListActors() -> Dictionary:
	return {"ok": true, "value": actors.values().duplicate(true)}

var previews: Array[String] = []
func ListRooks() -> Dictionary:
	var items: Array = []
	for id in rooks:
		items.append(SystemIntentReadRook("", id).value)
	return {"ok": true, "value": items}

func CurrentScene() -> Dictionary:
	return {"ok": true, "value": {"id": "main", "name": "Tabletop"}}

func PreviewRook(id: String, _target: Control) -> Dictionary:
	previews.append(id)
	return {"ok": true}

var selected_rook := "hero-rook"
var opened_surfaces: Array = []
var closed_surfaces := 0
func SelectedRookContext() -> Dictionary:
	return {"id": selected_rook}

func PresentationDevice() -> int:
	return 2

func ReadRook(id: String) -> Dictionary:
	return SystemIntentReadRook("", id)

func OpenWindowWithPresentation(scene: PackedScene, _options: Dictionary) -> void:
	opened_surfaces.append(scene.resource_path)

func CloseWindow(_scene: PackedScene) -> Dictionary:
	closed_surfaces += 1
	return {"ok": true}
