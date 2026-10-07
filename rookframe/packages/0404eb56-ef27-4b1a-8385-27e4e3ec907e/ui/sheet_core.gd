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
	add_theme_constant_override("separation", 5 if phone else 6 if tablet else 10)
	get_node(^"Likeness").size_flags_vertical = 1
	get_node(^"Likeness").custom_minimum_size = Vector2(get_node(^"Likeness").custom_minimum_size.x, 108 if phone else 132 if tablet else 170)
	get_node(^"Likeness/Vitals").add_theme_constant_override("separation", 0 if phone or tablet else 4)
	get_node(^"Likeness").add_theme_constant_override("separation", 10 if phone else 12 if tablet else 22)
	get_node(^"Likeness/Portrait").custom_minimum_size = Vector2(66, 98) if phone else Vector2(88, 118) if tablet else Vector2(136, 170)
	get_node(^"Abilities").add_theme_constant_override("v_separation", 0 if phone or tablet else 4)
	get_node(^"Abilities").add_theme_constant_override("h_separation", 8 if phone or tablet else 16)
	get_node(^"Class").custom_minimum_size = Vector2(get_node(^"Class").custom_minimum_size.x, 30 if tablet else 36)
	get_node(^"Class").add_theme_font_size_override("font_size", 22 if tablet else 28)
	var class_font: FontVariation = preload("res://rookframe/ui/theme/silkbound_medium.tres").duplicate()
	class_font.spacing_top = -1
	class_font.spacing_bottom = -1
	get_node(^"Class").add_theme_font_override("font", class_font)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style: StyleBox = get_node(^"Weapon").get_theme_stylebox(state).duplicate()
		if style is StyleBoxFlat:
			(style as StyleBoxFlat).bg_color = Color(0.203922, 0.239216, 0.254902, 1) if state in ["hover", "pressed"] else Color(0.137255, 0.156863, 0.168627, 1)
			(style as StyleBoxFlat).border_color = Color(0.356863, 0.384314, 0.396078, 1)
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		style.content_margin_left = 8 if tablet else 12
		get_node(^"Weapon").add_theme_stylebox_override(state, style)
	get_node(^"Origin").visible = false
	get_node(^"ManageEquipment").visible = false
	get_node(^"WeaponActions/Damage").visible = false
	get_node(^"PhoneHeader/PhoneEdit").visible = true
	var phone_font: FontVariation = preload("res://rookframe/ui/theme/silkbound_medium.tres").duplicate()
	phone_font.spacing_top = -2
	phone_font.spacing_bottom = -3
	get_node(^"PhoneHeader/PhoneName").add_theme_font_override("font", phone_font)
	get_node(^"ReadyWeapon").size_flags_vertical = 3 if phone else 1
	get_node(^"Protection").size_flags_vertical = 3 if phone else 1
	get_node(^"ProtectionItems").columns = 3 if tablet else 1
	get_node(^"Likeness/Vitals/PhoneClass").add_theme_font_size_override("font_size", 14)
	for path in [^"WeaponHeading/Actions/Center/Row", ^"ProtectionHeading/Center/Row"]:
		(get_node(path).get_node(^"Title") as Label).add_theme_font_size_override("font_size", 19 if tablet else 23)
		(get_node(path).get_node(^"Icon") as TextureRect).self_modulate = Color(0.815686, 0.745098, 0.556863, 1)
		(get_node(path).get_node(^"Icon") as TextureRect).custom_minimum_size = Vector2(22, 22) if tablet else Vector2(26, 26)
	get_node(^"WeaponHeading").custom_minimum_size = Vector2(get_node(^"WeaponHeading").custom_minimum_size.x, 28 if tablet else 44)
	get_node(^"ProtectionHeading").custom_minimum_size = Vector2(get_node(^"ProtectionHeading").custom_minimum_size.x, 28 if tablet else 44)
	get_node(^"Weapon").add_theme_font_size_override("font_size", 18 if tablet else 21)
	for path in [^"WeaponActions/Attack", ^"Dodge"]:
		var button: Button = get_node(path)
		button.custom_minimum_size = Vector2(button.custom_minimum_size.x, 44 if tablet else 61)
		(button.get_node(^"Summary/Copy/Title") as Label).add_theme_font_size_override("font_size", 17 if tablet else 21)
		(button.get_node(^"Summary/Copy/Subtitle") as Label).add_theme_font_size_override("font_size", 13 if tablet else 16)
		(button.get_node(^"Summary/Test/Value") as Label).add_theme_font_size_override("font_size", 20 if tablet else 24)
		(button.get_node(^"Summary/Test/Caption") as Label).add_theme_font_size_override("font_size", 13 if tablet else 16)
	get_node(^"WeaponActions/Attack/Summary/Damage/Value").add_theme_font_size_override("font_size", 20 if tablet else 24)
	get_node(^"WeaponActions/Attack/Summary/Damage/Caption").add_theme_font_size_override("font_size", 13 if tablet else 16)
	for path in [^"Likeness/Vitals/HitPointsEdit/HitPointsCurrentField/Editor", ^"Likeness/Vitals/HitPointsEdit/HitPointsMaximumField/Editor", ^"Likeness/Vitals/PowerUsesEdit/PowerUsesCurrentField/Editor", ^"Likeness/Vitals/OmensEdit/OmensCurrentField/Editor", ^"Abilities/StrengthRow/StrengthEditField/Editor", ^"Abilities/AgilityRow/AgilityEditField/Editor", ^"Abilities/PresenceRow/PresenceEditField/Editor", ^"Abilities/ToughnessRow/ToughnessEditField/Editor"]:
		var field = get_node(path)
		field.add_theme_font_size_override("font_size", 18 if phone or tablet else 20)
	for path in [^"Likeness/Vitals/HitPointsEdit/HitPointsCurrentField/Editor/Caption", ^"Likeness/Vitals/HitPointsEdit/HitPointsMaximumField/Editor/Caption", ^"Likeness/Vitals/PowerUsesEdit/PowerUsesCurrentField/Editor/Caption", ^"Likeness/Vitals/OmensEdit/OmensCurrentField/Editor/Caption", ^"Abilities/StrengthRow/StrengthEditField/Editor/Caption", ^"Abilities/AgilityRow/AgilityEditField/Editor/Caption", ^"Abilities/PresenceRow/PresenceEditField/Editor/Caption", ^"Abilities/ToughnessRow/ToughnessEditField/Editor/Caption"]:
		get_node(path).add_theme_font_size_override("font_size", 9 if phone or tablet else 11)


func configure(data: Dictionary, values: Dictionary, draft: Dictionary, items: Array, selected_weapon: String, owner: bool, action_live: bool) -> Dictionary:
	var phone := get_viewport_rect().size.x <= 900
	var tablet := get_viewport_rect().size.x <= 1300 and not phone
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
		get_node(^"Weapon").add_item(str(item.get("name", "Weapon")))
		if str(item.inventory_id) == str(selected_weapon):
			selected = index
	if weapons.is_empty():
		get_node(^"Weapon").add_item("No ready weapon")
		selected_weapon = ""
	else:
		selected_weapon = str(weapons[selected].inventory_id)
	get_node(^"Weapon").select(selected)
	get_node(^"ReadyWeapon").configure("Ready weapons  %d" % weapons.size(), "No ready weapon" if weapons.is_empty() else str(weapons[selected].get("name", "Weapon")), phone)
	var protection: Array[String] = []
	for child in get_node(^"ProtectionItems").get_children():
		get_node(^"ProtectionItems").remove_child(child)
		child.queue_free()
	for raw in items:
		var item: Dictionary = raw
		if item.get("equipped", false) and str(item.get("kind", "")) in ["Armor", "Shield"]:
			protection.append(str(item.get("reduction", "−1")))
			var button: Button = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_protection_row.tscn").instantiate()
			(button.get_node(^"Content/Name") as Label).text = str(item.get("name", "Protection"))
			(button.get_node(^"Content/Amount") as Label).text = str(item.get("reduction", "−1")) + " damage"
			(button.get_node(^"Content/Icon") as TextureRect).texture = load("res://rookframe/ui/icons/character/shield.svg" if item.get("kind") == "Shield" else "res://rookframe/ui/icons/character/armor.svg")
			(button.get_node(^"Content/Icon") as TextureRect).visible = not tablet
			(button.get_node(^"Content/Name") as Label).add_theme_font_size_override("font_size", 14 if tablet else 20)
			(button.get_node(^"Content/Amount") as Label).add_theme_font_size_override("font_size", 15 if tablet else 21)
			button.custom_minimum_size = Vector2(button.custom_minimum_size.x, 62 if tablet else 40)
			button.size_flags_horizontal = 3
			(button.get_node(^"Content") as BoxContainer).vertical = tablet
			(button.get_node(^"Content") as BoxContainer).add_theme_constant_override("separation", 1 if tablet else 8)
			(button.get_node(^"Content") as BoxContainer).offset_top = 10 if tablet else 0
			(button.get_node(^"Content") as BoxContainer).offset_bottom = -10 if tablet else 0
			(button.get_node(^"Content/Amount") as Label).clip_text = tablet
			button.configure_hint(str(item.get("name", "Protection")) + " · Protection", "While ready, the shield reduces incoming damage by 1." if item.get("kind") == "Shield" else "Armor is passive protection. Roll the amount to subtract from damage.", not phone)
			button.pressed.connect(_protection_pressed.bind(str(item.inventory_id)))
			get_node(^"ProtectionItems").add_child(button)
	get_node(^"Protection").configure("Protection & defence", "None" if protection.is_empty() else PROJECTION.new().text(protection).replace("\n", " · "), phone)
	var weapon: Dictionary = weapons[selected] if not weapons.is_empty() else {}
	var ranged := str(weapon.get("attack_ability", "Strength")) == "Presence"
	var modifier := int(values.get("Presence" if ranged else "Strength", 0))
	get_node(^"WeaponActions/Attack/Summary/Copy/Title").text = "Shoot" if ranged else "Cut"
	get_node(^"WeaponActions/Attack/Summary/Copy/Subtitle").text = "%s ft" % str(weapon.get("range_feet", 0)) if ranged else "Close"
	get_node(^"WeaponActions/Attack/Summary/Test/Value").text = ("%+d" % modifier).replace("-", "−")
	get_node(^"WeaponActions/Attack/Summary/Damage/Value").text = str(weapon.get("damage", "—"))
	get_node(^"Dodge/Summary/Test/Value").text = "1d20 %+d" % int(values.get("Agility", 0))
	get_node(^"WeaponActions/Attack").configure_hint(str(weapon.get("name", "Weapon")) + (" · Shoot" if ranged else " · Cut"), "Ranged attack using Presence." if ranged else "Melee attack using Strength.", not phone and not weapons.is_empty())
	get_node(^"Dodge").configure_hint("Defence", "Test Agility to avoid an incoming attack. The usual difficulty is DR12.", not phone)
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
	get_node(^"ManageEquipment").visible = false
	get_node(^"ProtectionHeading").visible = combat and not phone
	get_node(^"Protection").visible = combat and phone
	get_node(^"ProtectionItems").visible = combat and not phone
	get_node(^"ProtectionItems").visible = combat and not phone and get_node(^"ProtectionItems").get_child_count() > 0
	var defence_rule: StyleBoxFlat = get_node(^"Dodge").get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	defence_rule.border_width_top = 0
	get_node(^"Dodge").add_theme_stylebox_override("normal", defence_rule)
	get_node(^"Dodge").visible = combat and not phone
	get_node(^"ConditionReminder").visible = not combat
	get_node(^"ConditionReminder").configure(data, condition, phone)

func focused_entry() -> Control:
	for path in [^"WeaponHeading/Actions/Options", ^"Abilities/StrengthRow/Strength", ^"Abilities/AgilityRow/Agility", ^"Abilities/PresenceRow/Presence", ^"Abilities/ToughnessRow/Toughness"]:
		if get_node(path).has_focus():
			return get_node(path)
	return null

func _protection_pressed(id: String) -> void:
	entry_requested.emit("item:" + id)
