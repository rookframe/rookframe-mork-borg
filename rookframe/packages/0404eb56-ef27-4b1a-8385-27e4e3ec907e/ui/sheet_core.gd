extends VBoxContainer
const PROJECTION = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_projection.gd")
const BROKEN = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/broken_incident.gd")
const _ability_paths := {
	"Strength": ^"Abilities/StrengthRow/Strength",
	"Agility": ^"Abilities/AgilityRow/Agility",
	"Presence": ^"Abilities/PresenceRow/Presence",
	"Toughness": ^"Abilities/ToughnessRow/Toughness",
}
const _ability_edit_paths := {
	"StrengthEdit": ^"Abilities/StrengthRow/StrengthEditField/Editor",
	"AgilityEdit": ^"Abilities/AgilityRow/AgilityEditField/Editor",
	"PresenceEdit": ^"Abilities/PresenceRow/PresenceEditField/Editor",
	"ToughnessEdit": ^"Abilities/ToughnessRow/ToughnessEditField/Editor",
}
const _vital_paths := {
	"HitPoints": ^"Likeness/Vitals/HitPoints",
	"PowerUses": ^"Likeness/Vitals/PowerUses",
	"Omens": ^"Likeness/Vitals/Omens",
}
const _vital_group_paths := {
	"HitPointsEdit": ^"Likeness/Vitals/HitPointsEdit",
	"PowerUsesEdit": ^"Likeness/Vitals/PowerUsesEdit",
	"OmensEdit": ^"Likeness/Vitals/OmensEdit",
}
const _vital_edit_paths := {
	"HitPointsCurrent": ^"Likeness/Vitals/HitPointsEdit/HitPointsCurrentField/Editor",
	"HitPointsMaximum": ^"Likeness/Vitals/HitPointsEdit/HitPointsMaximumField/Editor",
	"PowerUsesCurrent": ^"Likeness/Vitals/PowerUsesEdit/PowerUsesCurrentField/Editor",
	"OmensCurrent": ^"Likeness/Vitals/OmensEdit/OmensCurrentField/Editor",
}

signal entry_requested(entry: String)
signal field_changed(text: String, field: String)

func _ready() -> void:
	get_node(^"WeaponHeading/Actions/Options").pressed.connect(_ready_weapon_pressed)
	for key in PROJECTION.ABILITIES:
		get_node(_ability_paths.get(str(key), ^"Abilities/StrengthRow/Strength")).pressed.connect(_ability_pressed.bind(str(key)))
		get_node(_ability_edit_paths.get(str(key) + "Edit", ^"Abilities/StrengthRow/StrengthEditField/Editor")).text_changed.connect(_field_typed.bind(str(key)))
	for pair in [["HitPointsCurrent", "hit_points"], ["HitPointsMaximum", "maximum_hit_points"], ["PowerUsesCurrent", "power_uses"], ["OmensCurrent", "omens"]]:
		get_node(_vital_edit_paths.get(str(pair[0]), ^"Likeness/Vitals/HitPointsEdit/HitPointsCurrentField/Editor")).text_changed.connect(_field_typed.bind(str(pair[1])))

func _ready_weapon_pressed() -> void:
	entry_requested.emit("ready_weapon")

func _ability_pressed(key: String) -> void:
	entry_requested.emit("ability:" + key)

func _field_typed(text: String, field: String) -> void:
	field_changed.emit(text, field)

func configure_layout(phone: bool, tablet: bool) -> void:
	custom_minimum_size = Vector2(228 if phone else 280 if tablet else 550, 0)
	add_theme_constant_override("separation", 4 if phone else 6 if tablet else 12)
	get_node(^"Likeness").size_flags_vertical = 3 if phone else 1
	get_node(^"Likeness/Vitals").add_theme_constant_override("separation", 0 if phone or tablet else 4)
	get_node(^"Likeness").add_theme_constant_override("separation", 12 if phone or tablet else 22)
	get_node(^"Likeness/Portrait").custom_minimum_size = Vector2(76, 95) if phone else Vector2(100, 125) if tablet else Vector2(152, 190)
	get_node(^"Abilities").add_theme_constant_override("v_separation", 2 if phone else 0 if tablet else 4)
	get_node(^"Abilities").add_theme_constant_override("h_separation", 8 if phone or tablet else 16)
	for path in [^"Weapon", ^"ManageEquipment", ^"Dodge", ^"Origin", ^"WeaponHeading", ^"ProtectionHeading"]:
		get_node(path).visible = not phone
	get_node(^"ReadyWeapon").visible = phone
	get_node(^"WeaponActions").visible = not phone
	get_node(^"Class").add_theme_font_size_override("font_size", 16 if tablet else 22)
	for path in [^"Likeness/Vitals/HitPointsEdit/HitPointsCurrentField/Editor", ^"Likeness/Vitals/HitPointsEdit/HitPointsMaximumField/Editor", ^"Likeness/Vitals/PowerUsesEdit/PowerUsesCurrentField/Editor", ^"Likeness/Vitals/OmensEdit/OmensCurrentField/Editor", ^"Abilities/StrengthRow/StrengthEditField/Editor", ^"Abilities/AgilityRow/AgilityEditField/Editor", ^"Abilities/PresenceRow/PresenceEditField/Editor", ^"Abilities/ToughnessRow/ToughnessEditField/Editor"]:
		var field = get_node(path)
		field.add_theme_font_size_override("font_size", 18 if phone or tablet else 20)
	for path in [^"Likeness/Vitals/HitPointsEdit/HitPointsCurrentField/Editor/Caption", ^"Likeness/Vitals/HitPointsEdit/HitPointsMaximumField/Editor/Caption", ^"Likeness/Vitals/PowerUsesEdit/PowerUsesCurrentField/Editor/Caption", ^"Likeness/Vitals/OmensEdit/OmensCurrentField/Editor/Caption", ^"Abilities/StrengthRow/StrengthEditField/Editor/Caption", ^"Abilities/AgilityRow/AgilityEditField/Editor/Caption", ^"Abilities/PresenceRow/PresenceEditField/Editor/Caption", ^"Abilities/ToughnessRow/ToughnessEditField/Editor/Caption"]:
		get_node(path).add_theme_font_size_override("font_size", 9 if phone or tablet else 11)


func configure(data: Dictionary, values: Dictionary, draft: Dictionary, items: Array, selected_weapon: String, owner: bool, action_live: bool) -> Dictionary:
	var phone := get_viewport_rect().size.y <= 560
	var tablet := get_viewport_rect().size.x <= 1150 and not phone
	get_node(^"PhoneHeader").visible = phone and draft.is_empty()
	get_node(^"PhoneHeader/PhoneName").text = str(data.get("name", "Character"))
	get_node(^"PhoneHeader/PhoneEdit").disabled = not owner or action_live
	get_node(^"Class").visible = not phone
	get_node(^"Likeness/Vitals/PhoneClass").visible = phone
	get_node(^"Likeness/Vitals/PhoneClass").text = str(data.get("class_title", "Character"))
	get_node(^"Class").text = str(data.get("class_title", "Character"))
	get_node(^"Origin").text = str(data.get("origin", "Origin"))
	get_node(^"Likeness/Vitals/HitPoints").configure("Hit points", int(data.get("hit_points", 0)), "/ %d" % int(data.get("maximum_hit_points", 1)), int(data.get("maximum_hit_points", 1)), phone, tablet)
	get_node(^"Likeness/Vitals/PowerUses").configure("Power uses", int(data.get("power_uses", 0)), "/ %d" % int(data.get("power_uses_total", 0)) if data.has("power_uses_total") else "", 0, phone, tablet)
	get_node(^"Likeness/Vitals/Omens").configure("Omens", int(data.get("omens", 0)), "available", 0, phone, tablet)
	for pair in [["HitPointsCurrent", "hit_points"], ["HitPointsMaximum", "maximum_hit_points"], ["PowerUsesCurrent", "power_uses"], ["OmensCurrent", "omens"]]:
		get_node(_vital_edit_paths.get(str(pair[0]), ^"Likeness/Vitals/HitPointsEdit/HitPointsCurrentField/Editor")).text = str(draft.get(str(pair[1]), "")) if not draft.is_empty() else str(values.get(str(pair[1]), ""))
	for ability in PROJECTION.ABILITIES:
		var key := str(ability)
		get_node(_ability_paths.get(key, ^"Abilities/StrengthRow/Strength")).configure(key, int(values.get(key, 0)), phone, tablet)
		get_node(_ability_paths.get(key, ^"Abilities/StrengthRow/Strength")).visible = draft.is_empty()
		get_node(_ability_edit_paths.get(key + "Edit", ^"Abilities/StrengthRow/StrengthEditField/Editor")).text = str(draft.get(key, "")) if not draft.is_empty() else str(values.get(key, "0"))
		get_node(_ability_edit_paths.get(key + "Edit", ^"Abilities/StrengthRow/StrengthEditField/Editor")).visible = not draft.is_empty()
	for vital in ["HitPoints", "PowerUses", "Omens"]:
		get_node(_vital_paths.get(str(vital), ^"Likeness/Vitals/HitPoints")).visible = draft.is_empty() and (not phone or vital != "Omens")
		get_node(_vital_group_paths.get(str(vital) + "Edit", ^"Likeness/Vitals/HitPointsEdit")).visible = not draft.is_empty() and (not phone or vital != "Omens")
	var weapons: Array[Dictionary] = []
	get_node(^"Weapon").clear()
	for raw in items:
		var item: Dictionary = raw
		if str(item.get("kind", "")) == "Weapon" and item.get("equipped", false) and int(item.get("quantity", 0)) > 0 and not item.get("broken", false):
			weapons.append(item)
	if str(data.get("class_id", "")) == "fanged-deserter":
		weapons.append({"inventory_id": "class:bite", "name": "Bite", "damage": "d6", "equipped": true, "quantity": 1})
	var selected := 0
	for index in range(weapons.size()):
		var item: Dictionary = weapons[index]
		get_node(^"Weapon").add_item(str(item.get("name", "Weapon")) + " · " + str(item.get("damage", "")))
		if str(item.inventory_id) == str(selected_weapon):
			selected = index
	if weapons.is_empty():
		get_node(^"Weapon").add_item("No ready weapon")
		selected_weapon = ""
	else:
		selected_weapon = str(weapons[selected].inventory_id)
	get_node(^"Weapon").select(selected)
	get_node(^"ReadyWeapon").configure("Ready weapons %d" % weapons.size(), "No ready weapon" if weapons.is_empty() else str(weapons[selected].get("name", "Weapon")), phone)
	var protection: Array[String] = []
	for raw in items:
		var item: Dictionary = raw
		if item.get("equipped", false) and str(item.get("kind", "")) in ["Armor", "Shield"]:
			protection.append(str(item.get("name", "")) + " " + str(item.get("reduction", "")))
	get_node(^"Protection").configure("Protection & reactions", "No protection" if protection.is_empty() else PROJECTION.new().text(protection).replace("\n", " · "), phone)
	var playable := owner and draft.is_empty() and not action_live and BROKEN.new().can_act(data)
	get_node(^"WeaponActions/Attack").disabled = not playable or weapons.is_empty()
	get_node(^"WeaponActions/Damage").disabled = not owner or not draft.is_empty() or action_live or weapons.is_empty()
	get_node(^"Dodge").disabled = not playable
	return {"weapons": weapons, "weapon": selected_weapon}

func configure_condition(data: Dictionary, condition: Dictionary, phone: bool) -> void:
	var combat := condition.is_empty()
	var can_attack := BROKEN.new().can_act(data)
	get_node(^"ReadyWeapon").visible = combat and phone
	get_node(^"WeaponHeading").visible = combat and not phone
	get_node(^"Weapon").visible = combat and not phone
	get_node(^"WeaponActions").visible = not combat or not phone
	get_node(^"WeaponActions/Attack").visible = can_attack
	get_node(^"ManageEquipment").visible = combat and not phone
	get_node(^"ProtectionHeading").visible = combat and not phone
	get_node(^"Protection").visible = combat
	get_node(^"Dodge").visible = combat and not phone
	get_node(^"ConditionReminder").visible = not combat
	get_node(^"ConditionReminder").configure(data, condition, phone)

func focused_entry() -> Control:
	for path in [^"WeaponHeading/Actions/Options", ^"Abilities/StrengthRow/Strength", ^"Abilities/AgilityRow/Agility", ^"Abilities/PresenceRow/Presence", ^"Abilities/ToughnessRow/Toughness"]:
		if get_node(path).has_focus():
			return get_node(path)
	return null
