extends "res://tests/creation_sdk_boundary.gd"
var device := 2
var language := "en"
const EN = preload(ROOT + "i18n/en.tres")
const RU = preload(ROOT + "i18n/ru.tres")
func PresentationDevice() -> int:
	return device
func SetWindowTitle(_title: String) -> Dictionary:
	return {"ok": true}
func ListContent(kind: int) -> Dictionary:
	if kind == 1:
		var entries: Array = []
		for id in ["classless", "fanged-deserter", "gutterborn-scum", "esoteric-hermit", "wretched-royalty", "heretical-priest", "occult-herbmaster"]:
			entries.append({"packageId": PackageId(), "localId": id + "-character", "displayName": id, "available": true, "type": "actor_definition"})
		return {"ok": true, "value": entries}
	return super.ListContent(kind)
func Translate(message: String, _domain: String) -> String:
	var translated := str((RU if language == "ru" else EN).get_message(message))
	return translated if not translated.is_empty() else message

var window: Control
var feedback_request: Dictionary = {}
func ShowFeedback(title: String, message: String, severity: String, actions: Array) -> int:
	feedback_request = {"title": title, "message": message, "severity": severity, "actions": actions}
	return 71

var return_parent: Node
func PushWindow(_source: Control, child: Control, _title: String) -> Dictionary:
	return_parent = child.get_parent()
	child.reparent(window.get_parent())
	child.theme = window.theme
	child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window.hide()
	child.show()
	return {"ok": true}
func PopWindow(child: Control) -> Dictionary:
	child.hide()
	child.reparent(return_parent)
	window.show()
	child.closed.emit()
	return {"ok": true}
