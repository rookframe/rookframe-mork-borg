extends VBoxContainer

const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const CHARACTER_DEFINITION = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/character_definition.gd")
const FIRST_EQUIPMENT_NAMES := ["Rope", "Torch", "Lantern with oil", "Magnesium strip", "Unclean scroll", "Sharp needle", "Medicine box", "Metal file", "Bear trap", "Bomb", "Red poison", "Silver crucifix"]
const SECOND_EQUIPMENT_NAMES := ["Life elixir", "Sacred scroll", "Small but vicious dog", "Monkeys", "Exquisite perfume", "Toolbox", "Heavy chain", "Grappling hook", "Shield", "Crowbar", "Lard", "Tent"]
const FIRST_EQUIPMENT_IDS := ["rope", "torch", "lantern-with-oil", "magnesium-strip", "unclean-scroll", "sharp-needle", "medicine-box", "metal-file", "bear-trap", "bomb", "poison-red", "crucifix-silver"]
const SECOND_EQUIPMENT_IDS := ["life-elixir", "sacred-scroll", "dog-small-but-vicious", "monkeys", "exquisite-perfume", "toolbox", "heavy-chain", "grappling-hook", "shield", "crowbar", "lard", "tent"]
const WEAPON_IDS := ["femur", "staff", "shortsword", "knife", "warhammer", "sword", "bow", "flail", "crossbow", "zweihander"]
const ARMOR_IDS := ["", "light-armor", "medium-armor", "heavy-armor"]
const PACK_IDS := ["backpack", "sack", "small-wagon", "donkey"]
const UNCLEAN_SCROLL_IDS := ["palms-open-the-southern-gate", "tongue-of-eris", "te-le-kin-esis", "lucy-fires-levitation", "daemon-of-capillaries", "nine-violet-signs-unknot-the-storm", "metzhuotl-blind-your-eye", "foul-psychompomp", "eyelid-blinds-the-mind", "death"]
const SACRED_SCROLL_IDS := ["grace-of-a-dead-saint", "grace-for-a-sinner", "whispers-pass-the-gate", "aegis-of-sorrow", "unmet-fate", "bestial-speech", "false-dawn-nights-chariot", "hermetic-step", "roskoes-consuming-glare", "enochian-syntax"]

signal roll_requested
signal stage_changed(step: int, title: String)
signal status_changed(message: String, error: bool)
signal busy_changed(value: bool)
signal primary_changed(text: String, disabled: bool)
signal character_created(actor: SDK.Actor)

var sdk: SDK
var _definitions: Array[SDK.ContentEntry] = []
var _character_definition: SDK.ContentEntry
var _character_miniatures: Array[SDK.ContentEntry] = []
var _character_miniature_choices: Array[Dictionary] = []
var _compact := false
var _character_content: VBoxContainer
var _status: Label
var _character_draft: Dictionary = {}
var _character_stage := "create-class"
var _creation_generation := 0
var _creation_active := false
var _busy := false
var _roll_ready := false
var _character_tab := "character"
var _character_name_field
var _character_description_field
var _character_fields: Dictionary = {}
var _preferred_miniature_index := 0
var _source_definition
@onready var _view := get_node(^"View")


func configure(definitions: Array[SDK.ContentEntry], character_definition: SDK.ContentEntry, miniatures: Array[SDK.ContentEntry], compact: bool, facade: SDK, miniature_choices: Array[Dictionary] = []) -> void:
	_definitions = definitions
	_character_definition = character_definition
	_character_miniatures = miniatures
	_character_miniature_choices = miniature_choices
	_compact = compact
	sdk = facade
	_character_content = self


func begin() -> void:
	_begin_character_creation()


func primary() -> void:
	_on_character_primary_action()


func start_over() -> void:
	_start_over_character()


func discard() -> void:
	_discard_character_creation()


func is_active() -> bool:
	return _creation_active


func clear_creation() -> void:
	_discard_character_creation()


func show_creation_route(route: String) -> void:
	_show_creation_route(route)


func _ready() -> void:
	_character_content = self
	_source_definition = CHARACTER_DEFINITION.new()
	_view.get_node(^"Aside/Context/Content/Pack").pressed.connect(_on_pack_pressed)
	_view.get_node(^"Aside/Context/Content/PreferredMiniature").pressed.connect(_cycle_preferred_miniature.bind(_view.get_node(^"Aside/Context/Content/PreferredMiniature")))


func _stage_index(stage: String) -> int:
	if stage == "create-abilities" or stage == "create-rolling":
		return 2
	if stage == "create-origin":
		return 3
	if stage == "create-equipment":
		return 4
	if stage == "create-identity":
		return 5
	if stage == "create-review":
		return 6
	return 1


func _route_blocked(route: String) -> bool:
	if _roll_ready:
		return false
	return bool(_character_draft.get("roll_pending", false)) or bool(_character_draft.get("equipment_roll_pending", false)) or bool(_character_draft.get("roll_failed", false)) or bool(_character_draft.get("equipment_roll_failed", false)) or route == "create-rolling"


func _show_creation_route(route: String) -> void:
	_character_stage = route
	_view.present_creation(route, _character_draft, _compact)
	_character_name_field = _view.get_node(^"Main/Content/Identity/Name") if route == "create-identity" else null
	_character_description_field = _view.get_node(^"Main/Content/Identity/Description") if route == "create-identity" else null
	var title: String = ["Choose a class", "Abilities", "Origin & Traits", "Equipment", "Identity", "Review character"][_stage_index(route) - 1]
	stage_changed.emit(_stage_index(route), title)
	var primary := "Create character" if route == "create-review" else ("Review character" if route == "create-identity" else "Continue")
	if bool(_character_draft.get("roll_pending", false)) or bool(_character_draft.get("equipment_roll_pending", false)):
		primary = "Roll %s" % str(_character_draft.get("active_roll", "")) if _roll_ready else "Rolling…"
	primary_changed.emit(primary, _route_blocked(route))


func _on_pack_pressed() -> void:
	var totals: Dictionary = _character_draft.get("equipment_rolls", {})
	var choices: Array[String] = _source_definition.pack_choices_for_roll(int(totals.get("Equipment pack", 0)))
	if not choices.is_empty():
		_cycle_pack(_view.get_node(^"Aside/Context/Content/Pack"), choices)
		_view.present_creation(_character_stage, _character_draft, _compact)


func _set_status(message: String, error: bool = false) -> void:
	status_changed.emit(message, error)


func _set_busy(value: bool, message: String, error: bool = false) -> void:
	_busy = value
	busy_changed.emit(value)
	_set_status(message, error)


func _begin_character_creation() -> void:
	if _busy or sdk == null or _character_definition == null:
		return
	_discard_character_creation()
	_creation_generation += 1
	_creation_active = true
	_character_stage = "create-class"
	_character_tab = "character"
	_character_draft = {
		"class_id": "classless",
		"class_title": "No Class",
		"abilities": {},
		"equipment_rolls": {},
		"inventory": [],
		"pack": "Nothing",
		"silver": 0,
		"omens": 0,
		"origin": "",
		"traits": [],
		"name": "",
		"description": "",
		"preferred_miniature": {},
		"starting_creature_ids": [],
		"starting_creature_grants": [],
		"companion_sheets": [],
		"roll_pending": false,
		"roll_failed": false,
		"equipment_roll_pending": false,
		"equipment_roll_failed": false,
	}
	_show_creation_route("create-class")
	_set_status("Choose the source-backed No Class profile.")


func _start_over_character() -> void:
	_begin_character_creation()


func _discard_character_creation() -> void:
	if not _creation_active:
		return
	_creation_generation += 1
	_creation_active = false
	_roll_ready = false
	roll_requested.emit()
	_character_draft = {}
	_character_stage = "create-class"
	_preferred_miniature_index = 0
	if _busy:
		_busy = false
		busy_changed.emit(false)


func _on_character_primary_action() -> void:
	if not _creation_active or _busy:
		return
	if _roll_ready:
		_roll_ready = false
		roll_requested.emit()
		return
	if _character_stage == "create-class":
		_character_stage = "create-rolling"
		_character_draft["roll_pending"] = true
		_character_draft["roll_failed"] = false
		_show_creation_route(_character_stage)
		_roll_character_abilities(_creation_generation)
	elif _character_stage == "create-rolling":
		_set_status("The source Rolls are still pending.")
	elif _character_stage == "create-abilities":
		if bool(_character_draft.get("roll_pending", false)):
			_set_status("The source Rolls are still pending.")
			return
		if bool(_character_draft.get("roll_failed", false)):
			_set_status("Start over to request fresh source Rolls.", true)
			return
		_character_stage = "create-origin"
		_show_creation_route(_character_stage)
	elif _character_stage == "create-origin":
		_character_stage = "create-equipment"
		_character_draft["equipment_roll_pending"] = true
		_character_draft["equipment_roll_failed"] = false
		_show_creation_route(_character_stage)
		_roll_character_equipment(_creation_generation)
	elif _character_stage == "create-equipment":
		if bool(_character_draft.get("equipment_roll_pending", false)):
			_set_status("Starting equipment Rolls are still pending.")
			return
		if bool(_character_draft.get("equipment_roll_failed", false)):
			_set_status("Start over to request fresh source Rolls.", true)
			return
		_character_stage = "create-identity"
		_show_creation_route(_character_stage)
	elif _character_stage == "create-identity":
		_sync_identity_fields()
		if str(_character_draft.get("name", "")).strip_edges().is_empty():
			_set_status("Enter a Character name before continuing.", true)
			return
		if _character_draft.get("preferred_miniature", {}).is_empty():
			_set_status("Choose a published Miniature before continuing.", true)
			return
		_character_stage = "create-review"
		_show_creation_route(_character_stage)
	elif _character_stage == "create-review":
		_sync_identity_fields()
		_commit_character()


func _roll_character_abilities(token: int) -> void:
	if not _creation_active or token != _creation_generation:
		return
	var abilities: Dictionary = {}
	_character_draft["abilities"] = abilities
	for ability_name in ["Agility", "Presence", "Strength", "Toughness"]:
		var result: SDK.DiceRollResult = await _automatic_roll(ability_name, 6, 3, token)
		if token != _creation_generation or not _creation_active:
			return
		if not result.ok:
			_character_draft["roll_pending"] = false
			_character_draft["roll_failed"] = true
			_character_stage = "create-abilities"
			_show_creation_route(_character_stage)
			_set_status(result.message, true)
			return
		var score := _roll_total(result)
		abilities[ability_name] = {"score": score, "modifier": _modifier(score)}
	_character_draft["abilities"] = abilities
	var hit_points_result: SDK.DiceRollResult = await _automatic_roll("Hit points", 8, 1, token)
	if token != _creation_generation or not _creation_active:
		return
	if not hit_points_result.ok:
		_character_draft["roll_pending"] = false
		_character_draft["roll_failed"] = true
		_character_stage = "create-abilities"
		_show_creation_route(_character_stage)
		_set_status(hit_points_result.message, true)
		return
	var rolled_hit_points := _roll_total(hit_points_result)
	var toughness: Dictionary = abilities.get("Toughness", {})
	var starting_hit_points: int = rolled_hit_points + int(toughness.get("modifier", 0))
	if starting_hit_points < 1:
		starting_hit_points = 1
	_character_draft["hit_points"] = starting_hit_points
	_character_draft["maximum_hit_points"] = starting_hit_points
	_character_draft["roll_pending"] = false
	_character_draft["roll_failed"] = false
	_character_stage = "create-abilities"
	_show_creation_route(_character_stage)
	_set_status("Automatic Rolls complete. Continue to Origin & Traits.")


func _roll_character_equipment(token: int) -> void:
	if not _creation_active or token != _creation_generation:
		return
	var totals: Dictionary = {}
	_character_draft["equipment_rolls"] = totals
	var base_terms := [["Silver", 6, 2], ["Omens", 2, 1], ["Food", 4, 1], ["Equipment pack", 6, 1], ["Equipment first", 12, 1], ["Equipment second", 12, 1]]
	for term in base_terms:
		var result: SDK.DiceRollResult = await _automatic_roll(term[0], term[1], term[2], token)
		if token != _creation_generation or not _creation_active:
			return
		if not result.ok:
			_character_draft["equipment_roll_pending"] = false
			_character_draft["equipment_roll_failed"] = true
			_character_stage = "create-equipment"
			_show_creation_route(_character_stage)
			_set_status(result.message, true)
			return
		totals[term[0]] = _roll_total(result, term[1])
	var first_roll := int(totals.get("Equipment first", 0))
	var second_roll := int(totals.get("Equipment second", 0))
	var conditional_terms: Array = []
	if first_roll == 5:
		conditional_terms.append(["Unclean scroll", 10, 1])
	if second_roll == 2:
		conditional_terms.append(["Sacred scroll", 10, 1])
	if first_roll == 11:
		conditional_terms.append(["Red poison doses", 4, 1])
	if second_roll == 1:
		conditional_terms.append(["Life elixir doses", 4, 1])
	if second_roll == 4:
		conditional_terms.append(["Monkey count", 4, 1])
	for term in conditional_terms:
		var conditional_result: SDK.DiceRollResult = await _automatic_roll(term[0], term[1], term[2], token)
		if token != _creation_generation or not _creation_active:
			return
		if not conditional_result.ok:
			_character_draft["equipment_roll_pending"] = false
			_character_draft["equipment_roll_failed"] = true
			_character_stage = "create-equipment"
			_show_creation_route(_character_stage)
			_set_status(conditional_result.message, true)
			return
		totals[term[0]] = _roll_total(conditional_result)
	var creature_roll_result: Dictionary = await _roll_starting_creature_grants(second_roll, totals, token)
	if token != _creation_generation or not _creation_active:
		return
	if not bool(creature_roll_result.get("ok", false)):
		_character_draft["equipment_roll_pending"] = false
		_character_draft["equipment_roll_failed"] = true
		_character_stage = "create-equipment"
		_show_creation_route(_character_stage)
		_set_status(str(creature_roll_result.get("message", "Starting Creature Roll failed.")), true)
		return
	var weapon_faces := 6 if first_roll == 5 or second_roll == 2 else 10
	var weapon_result: SDK.DiceRollResult = await _automatic_roll("Weapon", weapon_faces, 1, token)
	if token != _creation_generation or not _creation_active:
		return
	if not weapon_result.ok:
		_character_draft["equipment_roll_pending"] = false
		_character_draft["equipment_roll_failed"] = true
		_character_stage = "create-equipment"
		_show_creation_route(_character_stage)
		_set_status(weapon_result.message, true)
		return
	totals["Weapon"] = _roll_total(weapon_result)
	var armor_faces := 2 if first_roll == 5 or second_roll == 2 else 4
	var armor_result: SDK.DiceRollResult = await _automatic_roll("Armor", armor_faces, 1, token)
	if token != _creation_generation or not _creation_active:
		return
	if not armor_result.ok:
		_character_draft["equipment_roll_pending"] = false
		_character_draft["equipment_roll_failed"] = true
		_character_stage = "create-equipment"
		_show_creation_route(_character_stage)
		_set_status(armor_result.message, true)
		return
	totals["Armor"] = _roll_total(armor_result, armor_faces)
	_character_draft["equipment_rolls"] = totals
	_character_draft["silver"] = int(totals.get("Silver", 0)) * 10
	_character_draft["omens"] = int(totals.get("Omens", 0))
	var weapon_name: String = _source_definition.resolve_equipment_name("Weapon", int(totals.get("Weapon", 1)))
	var armor_name: String = _source_definition.resolve_equipment_name("Armor", int(totals.get("Armor", 1)))
	var pack_roll := int(totals.get("Equipment pack", 0))
	var pack_choices: Array[String] = _source_definition.pack_choices_for_roll(pack_roll)
	if pack_choices.is_empty():
		if pack_roll == 3:
			_character_draft["pack"] = "Backpack"
		elif pack_roll == 4:
			_character_draft["pack"] = "Sack"
		else:
			_character_draft["pack"] = "Nothing"
	else:
		_character_draft["pack"] = "Nothing"
	var inventory: Array = [
		{"name": "Waterskin", "source_item_id": "waterskin"},
		{"name": "Dried food", "source_item_id": "dried-food", "quantity": int(totals.get("Food", 0))},
	]
	if _character_draft["pack"] != "Nothing":
		inventory.append({"name": _character_draft["pack"], "source_item_id": _pack_id(str(_character_draft["pack"]))})
	var first_item := _first_equipment_item(first_roll, totals)
	var second_item := _second_equipment_item(second_roll, totals)
	if not first_item.is_empty():
		inventory.append(first_item)
	if first_roll == 8:
		inventory.append({"name": "Lockpicks", "source_item_id": "lockpicks"})
	if not second_item.is_empty():
		inventory.append(second_item)
	var weapon_id := _indexed_item_id(WEAPON_IDS, int(totals.get("Weapon", 0)))
	inventory.append({"name": weapon_name, "source_item_id": weapon_id, "roll": int(totals.get("Weapon", 0)), "kind": "Weapon", "equipped": true})
	var presence: Dictionary = _character_draft.get("abilities", {}).get("Presence", {})
	var ammunition_quantity := int(presence.get("modifier", 0)) + 10
	if weapon_id == "bow":
		inventory.append({"name": "Arrow", "source_item_id": "arrow", "quantity": ammunition_quantity})
	elif weapon_id == "crossbow":
		inventory.append({"name": "Bolt", "source_item_id": "bolt", "quantity": ammunition_quantity})
	if armor_name != "No armor":
		inventory.append({"name": armor_name, "source_item_id": _indexed_item_id(ARMOR_IDS, int(totals.get("Armor", 0))), "roll": int(totals.get("Armor", 0)), "kind": "Armor", "equipped": true})
	_character_draft["inventory"] = inventory
	var creature_grants: Array = creature_roll_result.get("grants", [])
	var starting_creature_ids: Array = _starting_creature_ids_for_grants(creature_grants)
	if starting_creature_ids.size() != creature_grants.size():
		_character_draft["equipment_roll_pending"] = false
		_character_draft["equipment_roll_failed"] = true
		_character_stage = "create-equipment"
		_show_creation_route(_character_stage)
		_set_status("The source requires a combat-profile Creature Actor, but its Package definition is unavailable.", true)
		return
	_character_draft["companion_sheets"] = []
	_character_draft["starting_creature_ids"] = starting_creature_ids
	_character_draft["starting_creature_grants"] = creature_grants
	_character_draft["equipment_roll_pending"] = false
	_character_draft["equipment_roll_failed"] = false
	_character_stage = "create-equipment"
	_show_creation_route(_character_stage)
	_set_status("Starting equipment is ready. Choose a source-defined pack.")


func _first_equipment_item(roll: int, totals: Dictionary) -> Dictionary:
	if roll < 1 or roll > FIRST_EQUIPMENT_NAMES.size():
		return {}
	var item := {"name": FIRST_EQUIPMENT_NAMES[roll - 1], "source_item_id": FIRST_EQUIPMENT_IDS[roll - 1]}
	if roll == 2:
		var presence: Dictionary = _character_draft.get("abilities", {}).get("Presence", {})
		var torch_quantity := int(presence.get("modifier", 0)) + 4
		item["quantity"] = 1 if torch_quantity < 1 else torch_quantity
	if roll == 5:
		var scroll_roll := int(totals.get("Unclean scroll", 0))
		item["roll"] = scroll_roll
		item["source_item_id"] = _indexed_item_id(UNCLEAN_SCROLL_IDS, scroll_roll)
		item["name"] = "Unclean scroll %d" % scroll_roll
	if roll == 7:
		var medicine_presence: Dictionary = _character_draft.get("abilities", {}).get("Presence", {})
		var medicine_uses := int(medicine_presence.get("modifier", 0)) + 4
		item["uses"] = 1 if medicine_uses < 1 else medicine_uses
	if roll == 11:
		item["uses"] = int(totals.get("Red poison doses", 0))
	return item


func _second_equipment_item(roll: int, totals: Dictionary) -> Dictionary:
	if roll < 1 or roll > SECOND_EQUIPMENT_NAMES.size():
		return {}
	var item := {"name": SECOND_EQUIPMENT_NAMES[roll - 1], "source_item_id": SECOND_EQUIPMENT_IDS[roll - 1]}
	if roll == 1:
		item["uses"] = int(totals.get("Life elixir doses", 0))
	if roll == 2:
		var scroll_roll := int(totals.get("Sacred scroll", 0))
		item["roll"] = scroll_roll
		item["source_item_id"] = _indexed_item_id(SACRED_SCROLL_IDS, scroll_roll)
		item["name"] = "Sacred scroll %d" % scroll_roll
	if roll == 4:
		item["quantity"] = int(totals.get("Monkey count", 0))
	return item


func _roll_starting_creature_grants(roll: int, totals: Dictionary, token: int) -> Dictionary:
	var grants: Array = []
	if roll == 3:
		var dog_result: SDK.DiceRollResult = await _automatic_roll("Dog hit points", 6, 1, token)
		if not dog_result.ok:
			return {"ok": false, "message": dog_result.message}
		var dog_hit_points := _roll_total(dog_result) + 2
		grants.append({"definition_id": "dog-small-but-vicious", "hit_points": dog_hit_points, "maximum_hit_points": dog_hit_points})
	elif roll == 4:
		var monkey_count := int(totals.get("Monkey count", 0))
		for monkey_index in range(monkey_count):
			var monkey_result: SDK.DiceRollResult = await _automatic_roll("Monkey %d hit points" % (monkey_index + 1), 4, 1, token)
			if not monkey_result.ok:
				return {"ok": false, "message": monkey_result.message}
			var monkey_hit_points := _roll_total(monkey_result) + 2
			grants.append({"definition_id": "monkey", "hit_points": monkey_hit_points, "maximum_hit_points": monkey_hit_points})
	return {"ok": true, "grants": grants}


func _indexed_item_id(ids: Array, roll: int) -> String:
	var index := roll - 1
	if index < 0 or index >= ids.size():
		return ""
	return str(ids[index])


func _pack_id(pack: String) -> String:
	if pack == "Backpack":
		return "backpack"
	if pack == "Sack":
		return "sack"
	if pack == "Small wagon":
		return "small-wagon"
	if pack == "Donkey":
		return "donkey"
	return ""


func _starting_creature_ids_for_grants(grants: Array) -> Array:
	var available: Array[String] = []
	for grant in grants:
		var grant_data: Dictionary = grant
		var candidate: String = grant_data.get("definition_id", "")
		if not candidate.is_empty() and _find_definition(candidate) != null:
			available.append(candidate)
	return available


func _automatic_roll(name: String, faces: int, count: int, token: int) -> SDK.DiceRollResult:
	_character_draft["active_roll"] = name
	_character_draft["roll_ready"] = true
	_roll_ready = true
	_show_creation_route(_character_stage)
	await roll_requested
	if token != _creation_generation or not _creation_active:
		return SDK.DiceRollResult.new({"ok": false, "message": "Character creation was discarded."})
	_character_draft["roll_ready"] = false
	_show_creation_route(_character_stage)
	_set_status("Rolling %s…" % name)
	await get_tree().process_frame
	if token != _creation_generation or not _creation_active:
		return SDK.DiceRollResult.new({"ok": false, "message": "Character creation was discarded."})
	# A d2 uses a physical d4, with each face pair mapped to one outcome.
	# Keep the physical result intact; apply the source die conversion when read.
	var physical_faces := 4 if faces == 2 else faces
	var roll_name := name + " (d2: d4 / 2, round up)" if faces == 2 else name
	return await sdk.dice.roll(SDK.DiceRequest.new([SDK.DiceTerm.new(roll_name, physical_faces, count)]))


func _roll_total(result: SDK.DiceRollResult, source_faces: int = 0) -> int:
	var total := 0
	for term in result.terms:
		for value in term.results:
			total += int((int(value) + 1) / 2) if source_faces == 2 else int(value)
	return total


func _modifier(score: int) -> int:
	if score <= 4:
		return -3
	if score <= 6:
		return -2
	if score <= 8:
		return -1
	if score <= 12:
		return 0
	if score <= 14:
		return 1
	if score <= 16:
		return 2
	return 3


func _sync_identity_fields() -> void:
	if _character_name_field != null:
		_character_draft["name"] = _character_name_field.get("value")
	if _character_description_field != null:
		_character_draft["description"] = _character_description_field.get("value")


func _cycle_pack(pack: Button, choices: Array) -> void:
	var index := 0
	for choice_index in range(choices.size()):
		if pack.text == "Pack: %s" % choices[choice_index]:
			index = choice_index + 1
	if index >= choices.size():
		index = 0
	pack.text = "Pack: %s" % choices[index]
	_character_draft["pack"] = choices[index]
	_replace_pack_inventory(str(choices[index]))


func _replace_pack_inventory(pack: String) -> void:
	var current_inventory: Array = _character_draft.get("inventory", [])
	var inventory: Array = []
	for raw_item in current_inventory:
		var item: Dictionary = raw_item
		if PACK_IDS.has(str(item.get("source_item_id", ""))):
			continue
		inventory.append(item)
	if pack != "Nothing":
		inventory.append({"name": pack, "source_item_id": _pack_id(pack)})
	_character_draft["inventory"] = inventory


func _cycle_preferred_miniature(miniature: Button) -> void:
	var index := _preferred_miniature_index + 1
	var available_count := _character_miniature_choices.size()
	if available_count > _character_miniatures.size():
		available_count = _character_miniatures.size()
	if index > available_count:
		index = 0
	if index == 0:
		miniature.text = "Choose a published Miniature"
	else:
		miniature.text = str(_character_miniature_choices[index - 1].get("title", "Published Miniature"))
	_preferred_miniature_index = index
	_set_preferred_miniature(index, miniature)


func _set_preferred_miniature(index: int, miniature: Button) -> void:
	if index <= 0 or index - 1 >= _character_miniatures.size():
		_character_draft["preferred_miniature"] = {}
		return
	if index - 1 >= _character_miniature_choices.size():
		_character_draft["preferred_miniature"] = {}
		return
	_character_draft["preferred_miniature"] = _character_miniature_choices[index - 1].duplicate(true)
	_character_draft["preferred_miniature"]["choice_index"] = index


func _commit_character() -> void:
	if _busy or not _creation_active or sdk == null or _character_definition == null:
		return
	var token := _creation_generation
	var choices: Dictionary = {
		"class_id": _character_draft.get("class_id", "classless"),
		"class_title": _character_draft.get("class_title", "No Class"),
		"abilities": _character_draft.get("abilities", {}),
		"inventory": _character_draft.get("inventory", []),
		"pack": _character_draft.get("pack", "Nothing"),
		"silver": _character_draft.get("silver", 0),
		"omens": _character_draft.get("omens", 0),
		"name": _character_draft.get("name", ""),
		"description": _character_draft.get("description", ""),
		"hit_points": _character_draft.get("hit_points", 1),
		"maximum_hit_points": _character_draft.get("maximum_hit_points", 1),
		"origin": _character_draft.get("origin", ""),
		"preferred_miniature": _character_draft.get("preferred_miniature", {}),
		"companion_sheets": _character_draft.get("companion_sheets", []),
		"starting_creature_ids": _character_draft.get("starting_creature_ids", []),
		"starting_creature_grants": _character_draft.get("starting_creature_grants", []),
	}
	for creature_id in choices["starting_creature_ids"]:
		var creature_id_text: String = creature_id
		if _find_definition(creature_id_text) == null:
			_set_busy(false, "Starting Creature grant %s is unavailable; Character was not created." % creature_id_text, true)
			return
	var child_requests: Array = []
	for creature_index in range(choices["starting_creature_ids"].size()):
		var creature_id_text: String = choices["starting_creature_ids"][creature_index]
		var creature_definition := _find_definition(creature_id_text)
		if creature_definition == null:
			_set_busy(false, "Starting Creature grant %s is unavailable; Character was not created." % creature_id_text, true)
			return
		var creature_choices: Dictionary = {}
		if creature_index < choices["starting_creature_grants"].size():
			creature_choices = choices["starting_creature_grants"][creature_index]
		child_requests.append({
			"package_id": creature_definition.reference.package_id,
			"local_id": creature_definition.reference.local_id,
			"choices": creature_choices,
		})
	_set_busy(true, "Creating Character and source-defined starting grants…")
	var result: SDK.ActorResult = await sdk.actors.create_atomic(_character_definition.reference, choices, child_requests)
	if token != _creation_generation or not _creation_active:
		return
	if not result.ok or result.actor == null:
		_set_busy(false, result.message if not result.ok else "Character was not created.", true)
		return
	_creation_active = false
	_roll_ready = false
	roll_requested.emit()
	_character_draft = {}
	_set_busy(false, "Character created with ordinary Owner access.")
	character_created.emit(result.actor)


func _find_definition(local_id: String) -> SDK.ContentEntry:
	for entry in _definitions:
		if entry.reference.local_id == local_id:
			return entry
	return null
