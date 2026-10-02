extends RefCounted

## One character-field draft. Inventory and Appearance never enter it.
var active := false
var _values: Dictionary = {}
var _changes: Dictionary = {}
var _identities: Dictionary = {}

func begin(values: Dictionary, identities: Dictionary) -> void:
	active = true
	_values = values.duplicate(true)
	_changes = {}
	_identities = identities.duplicate(true)

func refresh(values: Dictionary, identities: Dictionary) -> bool:
	var invalidated := false
	var retained: Dictionary = {}
	for key in _changes.keys():
		var field := str(key)
		if not values.has(field):
			invalidated = true
			continue
		var parts := field.split(":")
		if parts.size() == 3:
			var entry := parts[0] + ":" + parts[1]
			if str(_identities.get(entry, "")) != str(identities.get(entry, "")):
				invalidated = true
				continue
		retained[field] = str(_changes.get(field))
	_values = values.duplicate(true)
	_changes = retained
	_identities = identities.duplicate(true)

	return invalidated

func value(field: String) -> String:
	return str(_changes.get(field, _values.get(field, "")))

func change(field: String, text: String) -> void:
	_changes[field] = text

func changes() -> Dictionary:
	var changed: Dictionary = {}
	for key in _changes.keys():
		var field := str(key)
		if str(_changes.get(field)) != str(_values.get(field, "")):
			changed[field] = str(_changes.get(field))
	return changed

func identities() -> Dictionary:
	return _identities.duplicate(true)

func discard() -> void:
	active = false
	_changes = {}
