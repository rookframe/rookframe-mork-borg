extends BoxContainer
## A retained group of ordinary native fields; the Actor adapter owns its draft.
const FIELD = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_correction_field.tscn")
const FIELD_SCRIPT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_correction_field.gd")
const PROJECTION = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_projection.gd")
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
signal changed(field: String, text: String)
var _keys: Array = []
var entry_id := ""

func configure(keys: Array, values: Dictionary, locale: I18N, phone: bool, identity: String = "") -> void:
	if keys != _keys or identity != entry_id:
		for child in get_children():
			remove_child(child)
			child.queue_free()
		_keys = keys.duplicate()
		entry_id = identity
		for raw in keys:
			var key := str(raw)
			var field: FIELD_SCRIPT = FIELD.instantiate()
			add_child(field)
			var member := str(key.split(":")[-1])
			var title := PROJECTION.new().title(key if key.begins_with("armor:") else member)
			if key.begins_with("printed:"):
				title = "Printed dice formula"
			field.configure(key, locale.text(title), str(values.get(key, "")), member in ["rules", "text"])
			field.changed.connect(_typed)
	for child in get_children():
		var field := child as FIELD_SCRIPT
		field.configure_density(phone)
		field.sync_draft_value(str(values.get(field._field, "")))

func _typed(field: String, text: String) -> void:
	changed.emit(field, text)

func sync_field(key: String, text: String) -> void:
	for child in get_children():
		var field := child as FIELD_SCRIPT
		if field._field == key:
			field.sync_draft_value(text)

func set_fields_pending(active: bool) -> void:
	for child in get_children():
		var field := child as FIELD_SCRIPT
		field.set_editor_pending(active)

func show_error(key: String, message: String) -> bool:
	for child in get_children():
		var field := child as FIELD_SCRIPT
		if field._field == key:
			field.show_error(message)
			return true
	return false

func restore_focus(key: String = "") -> bool:
	for child in get_children():
		var field := child as FIELD_SCRIPT
		if key.is_empty() or field._field == key:
			field.restore_editor_focus()
			return true
	return false

func configure_density(phone: bool) -> void:
	for child in get_children():
		var field := child as FIELD_SCRIPT
		field.configure_density(phone)
