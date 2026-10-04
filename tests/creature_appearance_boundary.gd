extends "res://tests/miniature_boundary.gd"
## Only external host storage/portrait decoding is substituted by this SDK seam.
var before_appearance: Dictionary = {}

func SubmitSystemIntent(name: String, data: Variant) -> Dictionary:
	if name.begins_with("creature-appearance.") and not before_appearance.is_empty():
		actors.enemy.data = before_appearance.duplicate(true)
		before_appearance = {}
	return super.SubmitSystemIntent(name, data)

func DecodeActorPortrait(bytes: PackedByteArray) -> Dictionary:
	var image := Image.new()
	if bytes.is_empty() or image.load_png_from_buffer(bytes) != OK:
		return {"ok": false, "message": "Choose a valid PNG, JPEG or WebP portrait."}
	return {"ok": true, "texture": ImageTexture.create_from_image(image), "image": image.save_png_to_buffer()}
