extends RefCounted
## Local portrait presentation only. Adapters own mutation and session lifetimes.
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
var message := ""
var _path := ""
var _texture: Texture2D

func clear() -> void:
	_path = ""
	_texture = null
	message = ""

func resolve(value: Variant, portraits: SDK.ActorPortraits) -> Texture2D:
	var path: String = value if typeof(value) == TYPE_STRING else ""
	if path != _path:
		clear()
		_path = path
	# A reference may arrive before its retained file. Retry failures on the next
	# ordinary refresh, while successful decoding retains the texture identity.
	if not path.is_empty() and _texture == null:
		var decoded := portraits.decode(path)
		if decoded.ok:
			_texture = decoded.texture
			message = ""
		else:
			message = decoded.message
	if path.is_empty():
		message = ""
	if typeof(value) != TYPE_STRING:
		message = "Portrait is unavailable. Choose a replacement."
	return _texture
