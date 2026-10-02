extends HBoxContainer
signal miniature_requested
signal changed
signal message(text: String)
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ACTIONS = preload(ROOT + "logic/character_actions.gd")
const MINIATURES = preload(ROOT + "logic/miniature_actions.gd")
var _sdk: SDK
var _actor: SDK.Actor
var _busy := false
const PORTRAIT := ^"PortraitPanel/Inset/Content"
const MINIATURE := ^"MiniaturePanel/Inset/Content"

func _ready() -> void:
	get_node(PORTRAIT).get_node(^"PortraitButtons/ChangePortrait").pressed.connect(_choose_portrait)
	get_node(PORTRAIT).get_node(^"PortraitButtons/ClearPortrait").pressed.connect(_clear_portrait)
	get_node(MINIATURE).get_node(^"MiniatureButtons/ChangeMiniature").pressed.connect(_choose_miniature)
	get_node(MINIATURE).get_node(^"MiniatureButtons/ClearMiniature").pressed.connect(_clear_miniature)

func configure(facade: SDK, actor: SDK.Actor) -> void:
	_sdk = facade
	_actor = actor
	var owner := actor.access_level == "Owner"
	for path in [^"PortraitPanel/Inset/Content/PortraitButtons/ChangePortrait", ^"PortraitPanel/Inset/Content/PortraitButtons/ClearPortrait", ^"MiniaturePanel/Inset/Content/MiniatureButtons/ChangeMiniature", ^"MiniaturePanel/Inset/Content/MiniatureButtons/ClearMiniature"]:
		get_node(path).disabled = not owner or _busy
	var reference: Dictionary = actor.data.get("preferred_miniature", {})
	var content = get_node(MINIATURE)
	content.get_node(^"MiniaturePreview").visible = not reference.is_empty()
	content.get_node(^"EmptyPreview").visible = reference.is_empty()
	content.get_node(^"MiniatureButtons/ClearMiniature").visible = not reference.is_empty()
	content.get_node(^"MiniatureButtons/ChangeMiniature").text = "Choose miniature" if reference.is_empty() else "Change miniature"
	content.get_node(^"PackageCaption").text = ""
	content.get_node(^"MiniatureCaption").text = "No miniature selected"
	if reference.is_empty() or not is_visible_in_tree():
		return
	var entry := SDK.ContentReference.new(str(reference.get("package_id", "")), str(reference.get("local_id", "")))
	var found := _sdk.content.read(entry)
	content.get_node(^"MiniatureCaption").text = found.content_entry.localized_title if found.ok else "Miniature unavailable"
	content.get_node(^"PackageCaption").text = found.content_entry.package_title if found.ok else ""
	var preview := _sdk.content.preview_miniature(entry, content.get_node(^"MiniaturePreview"))
	if not preview.ok:
		message.emit(preview.message)

func portrait(data: Dictionary) -> Texture2D:
	var texture: Texture2D = preload("res://rookframe/ui/icons/character/character.svg")
	var caption := "No portrait selected"
	if data.has("portrait"):
		var image: PackedByteArray = data.get("portrait")
		var decoded := _sdk.portraits.decode(image)
		if decoded.ok:
			texture = decoded.texture
			caption = "Character portrait"
		else:
			caption = decoded.message
	get_node(PORTRAIT).get_node(^"PortraitPreview/Image").texture = texture
	get_node(PORTRAIT).get_node(^"PortraitPreview").accessibility_description = caption
	return texture

func _choose_miniature() -> void:
	miniature_requested.emit()

func _clear_miniature() -> void:
	if _busy or _actor == null or _actor.access_level != "Owner":
		return
	_busy = true
	_result(await MINIATURES.new(_sdk).set_actor(_actor.id, {}))

func _choose_portrait() -> void:
	if _busy or _actor == null or _actor.access_level != "Owner":
		return
	var actor_id := _actor.id
	_busy = true
	var selected := await _sdk.portraits.choose()
	if not selected.ok:
		_busy = false
		if selected.code != "cancelled":
			message.emit(selected.message)
		return
	if _actor == null or _actor.id.value != actor_id.value:
		_busy = false
		return
	_result(await ACTIONS.new(_sdk, actor_id).set_portrait(selected.image))

func _clear_portrait() -> void:
	if _busy or _actor == null or _actor.access_level != "Owner":
		return
	_busy = true
	_result(await ACTIONS.new(_sdk, _actor.id).set_portrait(PackedByteArray()))

func _result(result: SDK.ActorResult) -> void:
	_busy = false
	message.emit("Appearance updated." if result.ok else result.message)
	changed.emit()
