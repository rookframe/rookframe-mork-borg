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
	(get_node(^"PortraitPanel/Inset/Content/PortraitButtons/ChangePortrait") as Button).pressed.connect(_choose_portrait)
	(get_node(^"PortraitPanel/Inset/Content/PortraitButtons/ClearPortrait") as Button).pressed.connect(_clear_portrait)
	(get_node(^"MiniaturePanel/Inset/Content/MiniatureButtons/ChangeMiniature") as Button).pressed.connect(_choose_miniature)
	(get_node(^"MiniaturePanel/Inset/Content/MiniatureButtons/ClearMiniature") as Button).pressed.connect(_clear_miniature)

func configure(facade: SDK, actor: SDK.Actor) -> void:
	_sdk = facade
	_actor = actor
	var owner := actor.access_level == "Owner"
	for path in [^"PortraitPanel/Inset/Content/PortraitButtons/ChangePortrait", ^"PortraitPanel/Inset/Content/PortraitButtons/ClearPortrait", ^"MiniaturePanel/Inset/Content/MiniatureButtons/ChangeMiniature", ^"MiniaturePanel/Inset/Content/MiniatureButtons/ClearMiniature"]:
		get_node(path).disabled = not owner or _busy
	var data: Dictionary = actor.data
	var reference: Dictionary = data.get("preferred_miniature", {})
	var content = get_node(MINIATURE)
	(get_node(^"MiniaturePanel/Inset/Content/MiniaturePreview") as Control).visible = not reference.is_empty()
	(get_node(^"MiniaturePanel/Inset/Content/EmptyPreview") as Control).visible = reference.is_empty()
	(get_node(^"MiniaturePanel/Inset/Content/MiniatureButtons/ClearMiniature") as Control).visible = not reference.is_empty()
	(get_node(^"MiniaturePanel/Inset/Content/MiniatureButtons/ChangeMiniature") as Button).text = "Choose miniature" if reference.is_empty() else "Change miniature"
	(get_node(^"MiniaturePanel/Inset/Content/PackageCaption") as Label).text = ""
	(get_node(^"MiniaturePanel/Inset/Content/MiniatureCaption") as Label).text = "No miniature selected"
	if reference.is_empty() or not is_visible_in_tree():
		return
	var entry := SDK.ContentReference.new(str(reference.get("package_id", "")), str(reference.get("local_id", "")))
	var found := _sdk.content.read(entry)
	(get_node(^"MiniaturePanel/Inset/Content/MiniatureCaption") as Label).text = found.content_entry.localized_title if found.ok else "Miniature unavailable"
	(get_node(^"MiniaturePanel/Inset/Content/PackageCaption") as Label).text = found.content_entry.package_title if found.ok else ""
	var preview := _sdk.content.preview_miniature(entry, get_node(^"MiniaturePanel/Inset/Content/MiniaturePreview"))
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
	(get_node(^"PortraitPanel/Inset/Content/PortraitPreview/Image") as TextureRect).texture = texture
	(get_node(^"PortraitPanel/Inset/Content/PortraitPreview") as Control).accessibility_description = caption
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
