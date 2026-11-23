extends RefCounted

const SDK = preload("res://rookframe/sdk/package_sdk_facade.gd")
const CATALOGUE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/catalogue.gd")

class Reader extends RefCounted:
	static var _index: Dictionary = {}
	static var _values: Dictionary = {}

	func ReadData(path: String) -> Dictionary:
		var root := OS.get_environment("ROOKFRAME_TEST_PACKAGE_DATA")
		if root.is_empty():
			return {"ok": false, "message": "Compile test data with tests/run_character_creation.py."}
		if _index.is_empty():
			var index: Variant = _read(root.path_join("_rookframe_data/index.rfdata"))
			if not index is Dictionary or index.get("format") != "rookframe-package-data-index-v1":
				return {"ok": false, "message": "The compiled test data index is invalid."}
			_index = index.entries
		if not _index.has(path):
			return {"ok": false, "code": "missing_data", "message": path}
		if not _values.has(path):
			var block: Variant = _read(root.path_join(_index[path]))
			if not block is Dictionary or block.get("format") != "rookframe-package-data-v1":
				return {"ok": false, "message": "Invalid test data at " + path}
			_freeze(block.payload)
			_values[path] = block.payload
		return {"ok": true, "value": _values[path]}

	func _read(path: String) -> Variant:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			return null
		var value: Variant = file.get_var(false)
		return value if file.get_position() == file.get_length() else null

	func _freeze(value: Variant) -> void:
		if value is Dictionary:
			for member: Variant in value.values():
				_freeze(member)
			value.make_read_only()
		elif value is Array:
			for member: Variant in value:
				_freeze(member)
			value.make_read_only()

class DataFile extends "res://rookframe/sdk/scoped_file.gd":
	func read_data() -> SDK.DataResult:
		return SDK.DataResult.new(Reader.new().ReadData(_path))

class DataArea extends "res://rookframe/sdk/file_area.gd":
	func file(relative_name: String) -> ScopedFile:
		return DataFile.new(_scope, _area, relative_name)

static func reader() -> RefCounted:
	return Reader.new()

static func catalogue() -> CATALOGUE:
	return CATALOGUE.new(Reader.new())

static func facade(host: Object) -> SDK:
	var sdk := SDK.new(host)
	sdk.files._package = DataArea.new(sdk.files._scope, "package")
	return sdk
