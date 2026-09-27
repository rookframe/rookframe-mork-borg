extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
const CREATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_definition.gd")
const LIBRARY = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_library.gd")
var i18n := I18N.new()
var _definition: SDK.ContentReference
var _busy := false

func ready() -> void:
	if sdk == null:
		return
	i18n.bind(sdk)
	get_node("Layout/Tabs").set_tab_title(0, i18n.text("Creature"))
	get_node("Layout/Tabs").set_tab_title(1, i18n.text("Appearance"))
	get_node("Layout/Create").text = i18n.text("Create Actor")
	get_node("Layout/Create").pressed.connect(_create)
	get_node("Layout/Tabs/Appearance/Miniature/Choose").pressed.connect(_choose)
	get_node("Layout/Tabs/Appearance/Miniature/Clear").pressed.connect(_clear)
	get_node("MiniatureWorkflow").closed.connect(_miniature_closed)
	for path in ["Stats/HitPoints/Content/Label", "Stats/Morale/Content/Label", "Attacks/Content/Heading", "Rules/Content/Heading", "Stats/Protection/Content/Label", "Help"]:
		var control = get_node("Layout/Tabs/Creature/Preview/" + path)
		control.text = i18n.text(control.text)
	for path in ["Heading", "Help", "Choose", "Clear"]:
		var control = get_node("Layout/Tabs/Appearance/Miniature/" + path)
		control.text = i18n.text(control.text)

func opened_definition(definition: SDK.ContentReference) -> void:
	_definition = definition
	get_node("Layout").visible = true
	get_node("MiniatureWorkflow").visible = false
	_refresh()

func _refresh() -> void:
	if _definition == null:
		return
	var found := sdk.content.read(_definition)
	if not found.ok:
		get_node("Layout/Create").disabled = true
		return
	var source = CREATURES.new()
	source.resource_name = _definition.local_id
	var data: Dictionary = source.create_data({})
	var title: String = found.content_entry.localized_title
	sdk.windows.set_title(title)
	get_node("Layout/Tabs/Creature/Preview/Identity/Content/Title").text = title.to_upper()
	get_node("Layout/Tabs/Creature/Preview/Identity/Content/Portrait").visible = _definition.local_id == "seth-goblin"
	get_node("Layout/Tabs/Creature/Preview/Stats/HitPoints/Content/Value").text = str(data.get("hit_points", 0))
	var morale: Dictionary = data.get("morale", {})
	get_node("Layout/Tabs/Creature/Preview/Stats/Morale/Content/Value").text = str(morale.get("value", 0)) if str(morale.get("kind", "")) == "fixed" else (i18n.text("Special") if str(morale.get("kind", "")) == "special" else "—")
	var armor: Dictionary = data.get("armor", {})
	var reduction := str(armor.get("reduction", ""))
	get_node("Layout/Tabs/Creature/Preview/Stats/Protection/Content/Value").text = "—" if reduction.is_empty() else "−" + reduction
	get_node("Layout/Tabs/Creature/Preview/Rules/Content/Copy").text = i18n.text(str(data.get("rules", "")))
	get_node("Layout/Tabs/Creature/Preview/Rules").visible = not str(data.get("rules", "")).is_empty()
	var attacks: String = ""
	var attack_definitions: Array = data.get("attacks", [])
	for raw in attack_definitions:
		var attack: Dictionary = raw
		if not attacks.is_empty():
			attacks += "\n\n"
		attacks += i18n.text(str(attack.get("name", ""))) + " · " + str(attack.get("dice", "")) + ("\n" + i18n.text(str(attack.rules)) if attack.has("rules") else "")
	get_node("Layout/Tabs/Creature/Preview/Attacks/Content/Copy").text = attacks
	get_node("Layout/Create").disabled = _busy or not sdk.context().is_gm or not found.content_entry.available
	var miniature := _miniature()
	var content := sdk.content.read(SDK.ContentReference.new(str(miniature.get("package_id", "")), str(miniature.get("local_id", ""))))
	get_node("Layout/Tabs/Appearance/Miniature/Current").text = content.content_entry.localized_title if content.ok and content.content_entry.available else i18n.text("Saved Miniature unavailable. Choose a replacement.")
	get_node("Layout/Tabs/Appearance/Miniature/Choose").disabled = _busy or not sdk.context().is_gm
	get_node("Layout/Tabs/Appearance/Miniature/Clear").disabled = _busy or not sdk.context().is_gm

func _miniature() -> Dictionary:
	var saved := sdk.world_data.read()
	var data: Dictionary = saved.value.duplicate(true) if saved.ok and typeof(saved.value) == TYPE_DICTIONARY else {}
	var defaults: Dictionary = data.get("creature_miniatures", {}).duplicate(true)
	var id := str(_definition.local_id)
	var preferred: Dictionary = defaults.get(id, {})
	return CREATURES.new().effective_miniature({"definition_id": id, "preferred_miniature": preferred})

func _create() -> void:
	if _busy or _definition == null:
		return
	_busy = true
	_refresh()
	await LIBRARY.new(sdk).create(_definition)
	_busy = false
	_refresh()

func _choose() -> void:
	get_node("Layout").visible = false
	get_node("MiniatureWorkflow").open(sdk, i18n, null, _definition.local_id, _miniature())

func _miniature_closed(_saved: bool) -> void:
	get_node("Layout").visible = true
	_refresh()
	get_node("Layout/Tabs/Appearance/Miniature/Choose").grab_focus()

func _clear() -> void:
	if _busy:
		return
	_busy = true
	_refresh()
	var result := await sdk.system_actions.submit("miniature.default", {"definition": _definition.local_id, "package_id": "", "local_id": ""})
	var outcome: Dictionary = result.value if result.ok else {}
	var message: String = result.message if not result.ok else str(outcome.get("message", ""))
	get_node("Layout/Status").text = i18n.text(message)
	get_node("Layout/Status").visible = true
	_busy = false
	_refresh()
