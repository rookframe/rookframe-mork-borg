extends "res://tests/miniature_boundary.gd"
## Only external host storage/portrait decoding is substituted by this SDK seam.
var before_appearance: Dictionary = {}
var retained_portraits: Dictionary = {}
var fail_retention := false
var retention_calls := 0
var authority := true

func WorldContext() -> Dictionary:
	var result := super.WorldContext()
	result.value.is_authority = authority
	return result

func ReplaceWorldData(value: Variant) -> Dictionary:
	return SystemIntentCommitWorldData("", value, {})

func SubmitSystemIntent(name: String, data: Variant) -> Dictionary:
	if name.begins_with("creature-appearance.") and not before_appearance.is_empty():
		actors.enemy.data = before_appearance.duplicate(true)
		before_appearance = {}
	return super.SubmitSystemIntent(name, data)

func RetainActorPortrait(bytes: PackedByteArray) -> Dictionary:
	retention_calls += 1
	if fail_retention:
		return {"ok": false, "message": "Portrait retention failed"}
	var image := Image.new()
	if bytes.is_empty() or image.load_png_from_buffer(bytes) != OK:
		return {"ok": false, "message": "Choose a valid PNG, JPEG or WebP portrait."}
	for path in retained_portraits:
		if retained_portraits[path] == bytes:
			return {"ok": true, "path": path}
	var path := "portraits/selection-%d.png" % retained_portraits.size()
	retained_portraits[path] = bytes.duplicate()
	return {"ok": true, "path": path}

func DecodeActorPortrait(path: String) -> Dictionary:
	if not retained_portraits.has(path):
		return {"ok": false, "code": "portrait_unavailable", "message": "Portrait is unavailable. Choose a replacement."}
	var image := Image.new()
	if image.load_png_from_buffer(retained_portraits[path]) != OK:
		return {"ok": false, "message": "Choose a valid PNG, JPEG or WebP portrait."}
	return {"ok": true, "texture": ImageTexture.create_from_image(image), "path": path}
