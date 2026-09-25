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
