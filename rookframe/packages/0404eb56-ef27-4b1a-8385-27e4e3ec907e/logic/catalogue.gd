extends RefCounted

const SDK = preload("res://rookframe/sdk/package_sdk_facade.gd")
const CREATURES := "data/creatures.json"
const CLASSES := "data/classes.json"
const EQUIPMENT := "data/equipment.json"
const POWERS := "data/powers.json"
const ACTIONS := "data/actions.json"
const CREATION := "data/creation.json"
const SCROLL_FAMILIES := ["unclean", "sacred"]

var _content: RefCounted
var _sdk: SDK

func _init(content: RefCounted = null) -> void:
	_content = content

func bind(facade: SDK) -> void:
	_sdk = facade

func _read(logical_path: String) -> Dictionary:
	if _content != null:
		return _content.ReadData(logical_path)
	if _sdk == null:
		return {"ok": false, "message": "The Package data reader is unbound."}
	var file := _sdk.files.package.file(logical_path)
	var result: SDK.DataResult = file.read_data()
	return {"ok": result.ok, "value": result.value, "code": result.code, "message": result.message}

func _section(path: String, key: String, expected_type: int) -> Variant:
	var result := _read(path)
	if not result.get("ok", false):
		push_error("MÖRK BORG cannot read %s. %s %s" % [path, result.get("code", ""), result.get("message", "")])
		return null
	var value: Variant = result.get("value")
	if typeof(value) == TYPE_DICTIONARY:
		var group: Dictionary = value
		if typeof(group.get(key)) == expected_type:
			return group[key]
	push_error("MÖRK BORG data %s lacks a valid %s table." % [path, key])
	return null

func creature_profiles() -> Dictionary:
	return _section(CREATURES, "CORE_DEFINITIONS", TYPE_DICTIONARY)

func creature_profile(id: String) -> Dictionary:
	return creature_profiles().get(id, {})

func creature_details(id: String) -> Dictionary:
	var entries: Dictionary = _section(CREATURES, "ENTRIES", TYPE_DICTIONARY)
	return entries.get(id, {})

func miniature_id(id: String) -> String:
	var miniatures: Dictionary = _section(CREATURES, "AUTHORED_MINIATURES", TYPE_DICTIONARY)
	return miniatures.get(id, "")

func class_profiles() -> Dictionary:
	return _section(CLASSES, "PROFILES", TYPE_DICTIONARY)

func class_decoctions() -> Array:
	return _section(CLASSES, "DECOCTIONS", TYPE_ARRAY)

func equipment_rows() -> Array:
	return _section(EQUIPMENT, "ROWS", TYPE_ARRAY)

func scrolls(family: String) -> Array:
	var tables: Dictionary = _section(POWERS, "TABLES", TYPE_DICTIONARY)
	return tables.get(family, [])

func power_handling() -> Dictionary:
	return _section(POWERS, "HANDLING", TYPE_DICTIONARY)

func action_record(table: String, key: String) -> Variant:
	var records: Dictionary = _section(ACTIONS, table, TYPE_DICTIONARY)
	return records.get(key)

func creation_choices(table: String) -> Array:
	return _section(CREATION, table, TYPE_ARRAY)

func can_create_creature() -> bool:
	return (_section(CREATURES, "CORE_DEFINITIONS", TYPE_DICTIONARY) != null
		and _section(CREATURES, "ENTRIES", TYPE_DICTIONARY) != null
		and _section(CREATURES, "AUTHORED_MINIATURES", TYPE_DICTIONARY) != null)

func can_create_character() -> bool:
	return (_section(CLASSES, "PROFILES", TYPE_DICTIONARY) != null
		and _section(CLASSES, "DECOCTIONS", TYPE_ARRAY) != null
		and _section(CREATION, "PACK_CHOICES", TYPE_ARRAY) != null
		and _section(CREATION, "STARTING_CREATURES", TYPE_ARRAY) != null
		and _section(CREATION, "SOURCE_CREATURE_CHOICES", TYPE_ARRAY) != null)
