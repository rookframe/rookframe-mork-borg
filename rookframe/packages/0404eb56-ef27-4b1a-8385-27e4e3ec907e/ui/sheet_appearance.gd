extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_sheet_appearance.gd"
signal changed
signal message(text: String)
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ACTIONS = preload(ROOT + "logic/character_actions.gd")
const MINIATURES = preload(ROOT + "logic/miniature_actions.gd")
var _sdk: SDK
var _actor: SDK.Actor
var _busy := false
var _locale := I18N.new()
var _texture: Texture2D

func _ready() -> void:
	super._ready()
	portrait_requested.connect(_choose_portrait)
	portrait_reset_requested.connect(_clear_portrait)
	miniature_clear_requested.connect(_clear_miniature)

func configure_actor(facade: SDK, actor: SDK.Actor) -> void:
	_sdk = facade
	_actor = actor
	_locale.bind(facade)
	configure_layout(get_viewport_rect().size.x <= 900, get_viewport_rect().size.x > 900 and get_viewport_rect().size.x <= 1300)
	var owner := actor.access_level == "Owner"
	for path in [^"Columns/PortraitPanel/Inset/Content/PortraitButtons/ChangePortrait", ^"Columns/PortraitPanel/Inset/Content/PortraitButtons/ClearPortrait", ^"Columns/MiniaturePanel/Inset/Content/MiniatureButtons/ChangeMiniature", ^"Columns/MiniaturePanel/Inset/Content/MiniatureButtons/ClearMiniature"]:
		get_node(path).disabled = not owner or _busy
	var data: Dictionary = actor.data
	var reference: Dictionary = data.get("preferred_miniature", {})
	(get_node(^"Columns/MiniaturePanel/Inset/Content/MiniaturePreview") as Control).visible = not reference.is_empty()
	(get_node(^"Columns/MiniaturePanel/Inset/Content/EmptyPreview") as Control).visible = reference.is_empty()
	(get_node(^"Columns/MiniaturePanel/Inset/Content/MiniatureButtons/ClearMiniature") as Control).visible = not reference.is_empty()
	(get_node(^"Columns/MiniaturePanel/Inset/Content/MiniatureButtons/ChangeMiniature") as Button).text = "Choose miniature" if reference.is_empty() else "Change miniature"
	(get_node(^"Columns/MiniaturePanel/Inset/Content/PackageCaption") as Label).text = ""
	(get_node(^"Columns/MiniaturePanel/Inset/Content/MiniatureCaption") as Label).text = "No miniature selected"
	miniature(_locale, "", "", not reference.is_empty())
	get_node(MINIATURE + "PreviewCaptionGap").visible = not reference.is_empty()
	if reference.is_empty() or not is_visible_in_tree():
		return
	var entry := SDK.ContentReference.new(str(reference.get("package_id", "")), str(reference.get("local_id", "")))
	var found := _sdk.content.read(entry)
	(get_node(^"Columns/MiniaturePanel/Inset/Content/MiniatureCaption") as Label).text = found.content_entry.localized_title if found.ok else "Miniature unavailable"
	(get_node(^"Columns/MiniaturePanel/Inset/Content/PackageCaption") as Label).text = found.content_entry.package_title if found.ok else ""
	var preview := _sdk.content.preview_miniature(entry, get_node(^"Columns/MiniaturePanel/Inset/Content/MiniaturePreview"))
	if not preview.ok:
		message.emit(preview.message)

func portrait(data: Dictionary) -> Texture2D:
	var texture: Texture2D = preload("res://rookframe/ui/icons/character/character.svg")
	var caption := "No portrait selected"
	if data.has("portrait"):
		var path: String = data.get("portrait", "") if typeof(data.get("portrait", "")) == TYPE_STRING else ""
		var decoded := _sdk.portraits.decode(path)
		if decoded.ok:
			texture = decoded.texture
			caption = "Character portrait"
		else:
			caption = decoded.message
	(get_node(^"Columns/PortraitPanel/Inset/Content/PortraitPreview/Image") as TextureRect).texture = texture
	(get_node(^"Columns/PortraitPanel/Inset/Content/PortraitPreview") as Control).accessibility_description = caption
	_texture = texture
	return texture

func _choose_miniature() -> void:
	miniature_requested.emit()

func _present_actions() -> void:
	for base in [PORTRAIT, MINIATURE]:
		var buttons: HFlowContainer = get_node(base + ("PortraitButtons" if base == PORTRAIT else "MiniatureButtons"))
		for child in buttons.get_children():
			var button := child as Button
			button.icon = null
			button.theme_type_variation = ""
			if not str(button.name).begins_with("Change"):
				button.text = "Reset"
			button.accessibility_name = button.text
			button.tooltip_text = button.text

func _clear_miniature() -> void:
	if _busy or _actor == null or _actor.access_level != "Owner":
		return
	_busy = true
	_result(await MINIATURES.new(_sdk).set_actor(_actor.id, {}))

func _choose_portrait() -> void:
	if _busy or _actor == null or _actor.access_level != "Owner":
		return
	var actor_id := _actor.id
	var data: Dictionary = _actor.data
	var expected := str(data.get("portrait", ""))
	var revision := int(data.get("portrait_revision", 0))
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
	_result(await ACTIONS.new(_sdk, actor_id).set_portrait(selected.path, expected, revision))

func _clear_portrait() -> void:
	if _busy or _actor == null or _actor.access_level != "Owner":
		return
	_busy = true
	var data: Dictionary = _actor.data
	_result(await ACTIONS.new(_sdk, _actor.id).set_portrait("", str(data.get("portrait", "")), int(data.get("portrait_revision", 0))))

func _result(result: SDK.ActorResult) -> void:
	_busy = false
	message.emit("Appearance updated." if result.ok else result.message)
	changed.emit()

func configure_layout(phone: bool, tablet: bool) -> void:
	var data: Dictionary = _actor.data if _actor != null else {}
	super.configure(_locale, _texture, false, _actor != null and _actor.access_level == "Owner" and not _busy, phone, tablet, str(data.get("name", "Character")))
	get_node(PORTRAIT + "Explanation").text = "Shown in the character sheet."
	get_node(MINIATURE + "Explanation").text = "Saved for this character. Existing Rooks keep their current miniature."
	get_node(^"Intro/Title").add_theme_color_override("font_color", Color(0.905882, 0.905882, 0.866667, 1))
	for path in [^"Intro/Title", ^"Columns/PortraitPanel/Inset/Content/PortraitHeading/Title", ^"Columns/MiniaturePanel/Inset/Content/MiniatureHeading/Title", ^"Columns/MiniaturePanel/Inset/Content/EmptyPreview/Content/Title", ^"Columns/MiniaturePanel/Inset/Content/MiniatureCaption"]:
		get_node(path).add_theme_font_override("font", preload("res://rookframe/ui/theme/silkbound_medium.tres"))
	for base in [PORTRAIT, MINIATURE]:
		var heading: Control = get_node(base + ("PortraitHeading" if base == PORTRAIT else "MiniatureHeading"))
		(heading.get_node(^"Icon") as TextureRect).self_modulate = Color(0.815686, 0.745098, 0.556863, 1)
		var panel: PanelContainer = get_node(^"Columns/PortraitPanel" if base == PORTRAIT else ^"Columns/MiniaturePanel")
		var wash: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		wash.bg_color = Color(0.137255, 0.156863, 0.168627, 0.45)
		wash.border_color = Color(0.356863, 0.384314, 0.396078, 1)
		panel.add_theme_stylebox_override("panel", wash)
		var buttons: HFlowContainer = get_node(base + ("PortraitButtons" if base == PORTRAIT else "MiniatureButtons"))
		buttons.add_theme_constant_override("h_separation", 12)
		buttons.add_theme_constant_override("v_separation", 8)
		for child in buttons.get_children():
			var button := child as Button
			var primary := str(button.name).begins_with("Change")
			if not primary:
				button.text = "Reset"
			button.add_theme_font_size_override("font_size", 14 if phone else 16 if tablet else 18)
			for state in ["normal", "hover", "pressed", "disabled"]:
				var frame: StyleBoxFlat = button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
				frame.bg_color = Color(0.807843, 0.8, 0.701961, 1) if primary else Color(0.137255, 0.156863, 0.168627, 1)
				frame.border_color = Color(0.356863, 0.384314, 0.396078, 1)
				button.add_theme_stylebox_override(state, frame)
			for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
				button.add_theme_color_override(state, Color(0.082353, 0.090196, 0.098039, 1) if primary else Color(0.905882, 0.905882, 0.866667, 1))
	get_node(MINIATURE + "EmptyPreview/Content/Image").self_modulate = Color(0.815686, 0.745098, 0.556863, 0.4)
