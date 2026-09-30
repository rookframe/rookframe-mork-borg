extends VBoxContainer

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()

const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const SCROLLS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/starting_scrolls.gd")
const PLAN = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creation_roll_plan.gd")
var _roll_plan := PLAN.new()
const CLASSES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creation_classes.gd")
const CHARACTER_DEFINITION = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/character_definition.gd")
const FIRST_EQUIPMENT_NAMES = CHARACTER_DEFINITION.FIRST_EQUIPMENT_NAMES
const SECOND_EQUIPMENT_NAMES = CHARACTER_DEFINITION.SECOND_EQUIPMENT_NAMES
const FIRST_EQUIPMENT_IDS := ["rope", "torch", "lantern-with-oil", "magnesium-strip", "unclean-scroll", "sharp-needle", "medicine-box", "metal-file", "bear-trap", "bomb", "poison-red", "crucifix-silver"]
const SECOND_EQUIPMENT_IDS := ["life-elixir", "sacred-scroll", "dog-small-but-vicious", "monkeys", "exquisite-perfume", "toolbox", "heavy-chain", "grappling-hook", "shield", "crowbar", "lard", "tent"]
const WEAPON_IDS := ["femur", "staff", "shortsword", "knife", "warhammer", "sword", "bow", "flail", "crossbow", "zweihander"]
const ARMOR_IDS := ["", "light-armor", "medium-armor", "heavy-armor"]
const PACK_IDS := ["backpack", "sack", "small-wagon", "donkey"]

signal scroll_choice_requested(slot: String)
signal pack_choice_requested
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
var _pending_roll_ids: Array[String] = []
var _creation_active := false
var _busy := false
var _rolling: Array[String] = []
var _next_roll: Dictionary = {}
var _roll_ready := false
var _character_tab := "character"
var _character_name_field
var _character_description_field
var _character_fields: Dictionary = {}
var _source_definition
@onready var _view := get_node(^"View")


func configure(definitions: Array[SDK.ContentEntry], character_definition: SDK.ContentEntry, miniatures: Array[SDK.ContentEntry], compact: bool, facade: SDK, miniature_choices: Array[Dictionary] = []) -> void:
	_definitions = definitions
	_character_definition = _find_definition(str(_character_draft.get("class_id", "classless")) + "-character") if _creation_active else character_definition
	_character_miniatures = miniatures
	_character_miniature_choices = miniature_choices
	_compact = compact
	sdk = facade
	_view.facade = facade
	i18n.bind(sdk)
	localize(i18n)
	_character_content = self


func begin() -> void:
	_begin_character_creation()


func select_class(class_id: String) -> void:
	if not _creation_active or _character_stage != "create-class":
		return
	var profile: Dictionary = CLASSES.new().profile(class_id)
	var definition := _find_definition(class_id + "-character")
	if profile.is_empty() or definition == null:
		return
	if class_id != str(_character_draft.get("class_id", "classless")) and int(_character_draft.get("furthest_step", 1)) > 1:
		_sync_identity_fields()
		var identity := {}
		for key in ["name", "description", "preferred_miniature"]:
			identity[key] = _character_draft.get(key)
		_begin_character_creation()
		for key in ["name", "description", "preferred_miniature"]:
			_character_draft[key] = identity[key]
	_character_definition = definition
	_character_draft["class_id"] = class_id
	_character_draft["class_title"] = str(profile.get("title", ""))
	_character_draft["class_profile"] = profile
	_character_draft["class_rules"] = profile.get("rules", [])
	_show_creation_route("create-class")


func choose_scroll_disposition(slot: String, disposition: String) -> void:
	if not _creation_active or _busy or str(_character_draft.get("scroll_choice_slot", "")) != slot:
		return
	if not ["reroll", "eat", "toilet-paper"].has(disposition):
		return
	var dispositions: Array = _character_draft.get("scroll_dispositions", [])
	dispositions.append({"slot": slot, "disposition": disposition, "equipment_roll": 5 if slot == "first" else 2})
	_character_draft["scroll_dispositions"] = dispositions
	_character_draft["scroll_choice_slot"] = ""
	if disposition == "reroll":
		var totals: Dictionary = _character_draft.get("equipment_rolls", {})
		totals.erase("Equipment " + slot)
	_refresh_rolls()


func primary() -> void:
	_on_character_primary_action()

func back() -> void:
	if not can_go_back():
		return
	_sync_identity_fields()
	var routes := ["create-class", "create-abilities", "create-origin", "create-equipment", "create-identity", "create-review"]
	_show_creation_route(routes[_stage_index(_character_stage) - 2])

func can_go_back() -> bool:
	var pending := bool(_character_draft.get("roll_pending", false)) or bool(_character_draft.get("equipment_roll_pending", false))
	return _creation_active and not _busy and _stage_index(_character_stage) > 1 and (not pending or _roll_ready or not str(_character_draft.get("scroll_choice_slot", "")).is_empty())


func start_over() -> void:
	_start_over_character()


func discard() -> void:
	_discard_character_creation()


func is_active() -> bool:
	return _creation_active


func capture_reconnect_state() -> Dictionary:
	if not _creation_active:
		return {}
	_sync_identity_fields()
	return {"draft": _character_draft.duplicate(true), "stage": _character_stage}


func restore_reconnect_state(state: Dictionary) -> void:
	_discard_character_creation()
	var draft: Dictionary = state.get("draft", {})
	_character_draft = draft.duplicate(true)
	if _character_draft.is_empty():
		return
	_character_draft["rolling"] = []
	var reroll := str(_character_draft.get("scroll_reroll_slot", ""))
	if not reroll.is_empty():
		var totals: Dictionary = _character_draft.get("equipment_rolls", {})
		totals.erase("Equipment " + reroll)
		_character_draft.erase("scroll_reroll_slot")
	_creation_active = true
	_character_definition = _find_definition(str(_character_draft.get("class_id", "classless")) + "-character")
	_character_stage = str(state.get("stage", "create-class"))
	_show_creation_route(_character_stage)
	# Restoration is plain data only. Fresh Rolls still require a button press;
	# never reuse the old facade or resubmit its interrupted command.
	_resume_creation.call_deferred()


func _resume_creation() -> void:
	_refresh_rolls()


func clear_creation() -> void:
	_discard_character_creation()


func show_creation_route(route: String) -> void:
	_show_creation_route(route)


func _ready() -> void:
	_view.class_selected.connect(select_class)
	_view.scroll_selected.connect(choose_scroll_disposition)
	_character_content = self
	_source_definition = CHARACTER_DEFINITION.new()
	_view.pack_selected.connect(_on_pack_selected)
	_view.miniature_requested.connect(_choose_preferred_miniature)
	get_node(^"MiniaturePicker").selected.connect(_miniature_selected)
	get_node(^"MiniaturePicker").closed.connect(_miniature_picker_closed)


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
	if _stage_index(route) < int(_character_draft.get("furthest_step", 1)):
		return false
	if route == "create-equipment" and bool(_character_draft.get("pack_choice_pending", false)):
		return true
	if not str(_character_draft.get("scroll_choice_slot", "")).is_empty():
		return true
	if _roll_ready:
		return false
	return bool(_character_draft.get("roll_pending", false)) or bool(_character_draft.get("equipment_roll_pending", false)) or bool(_character_draft.get("roll_failed", false)) or bool(_character_draft.get("equipment_roll_failed", false)) or route == "create-rolling"


func _show_creation_route(route: String) -> void:
	_character_stage = route
	_character_draft["furthest_step"] = maxi(_stage_index(route), int(_character_draft.get("furthest_step", 1)))
	_view.present_creation(route, _character_draft, _compact)
	_view.set_back_enabled(can_go_back())
	_character_name_field = _view.get_name_field() if route == "create-identity" else null
	_character_description_field = _view.get_description_field() if route == "create-identity" else null
	var title: String = ["Choose a class", "Abilities", "Origin & Traits", "Equipment", "Identity", "Review character"][_stage_index(route) - 1]
	stage_changed.emit(_stage_index(route), title)
	var primary := "Create character" if route == "create-review" else ("Review character" if route == "create-identity" else "Continue")
	if _stage_index(route) == int(_character_draft.get("furthest_step", 1)) and (bool(_character_draft.get("roll_pending", false)) or bool(_character_draft.get("equipment_roll_pending", false))):
		primary = _t("Roll %s") % _t(str(_character_draft.get("active_roll", ""))) if _roll_ready else "Rolling…"
	if route == "create-equipment" and bool(_character_draft.get("pack_choice_pending", false)):
		primary = "Choose a pack"
	if route == "create-equipment" and not str(_character_draft.get("scroll_choice_slot", "")).is_empty():
		primary = "Choose scroll use"
	primary_changed.emit(primary, _route_blocked(route))


func _on_pack_selected(pack: String) -> void:
	if not _creation_active or _character_stage != "create-equipment":
		return
	var totals: Dictionary = _character_draft.get("equipment_rolls", {})
	var choices: Array = _source_definition.pack_choices_for_roll(int(totals.get("Equipment pack", 0)))
	if choices.has(pack):
		_character_draft["pack"] = pack
		_replace_pack_inventory(pack)
		_character_draft["pack_choice_pending"] = false
		_refresh_rolls()
		_show_creation_route(_character_stage)


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
		"creation_id": sdk.dice.new_request_id(),
		"class_id": "classless",
		"class_title": "No Class",
		"class_profile": CLASSES.new().profile("classless"),
		"class_rules": [],
		"abilities": {},
		"equipment_rolls": {},
		"roll_faces": {},
		"inventory": [],
		"pack": "Nothing",
		"silver": 0,
		"omens": 0,
		"origin": "",
		"traits": [],
		"scroll_dispositions": [],
		"scroll_choice_slot": "",
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
	_character_definition = _find_definition("classless-character")
	_show_creation_route("create-class")
	_set_status("Choose a class to begin.")


func _start_over_character() -> void:
	_begin_character_creation()


func _discard_character_creation() -> void:
	if not _creation_active:
		return
	_creation_generation += 1
	_creation_active = false
	var abandoned := _pending_roll_ids.duplicate()
	_pending_roll_ids.clear()
	for request_id in abandoned:
		sdk.dice.cancel_roll(request_id)
	_rolling.clear()
	_next_roll = {}
	_roll_ready = false
	_character_draft = {}
	_character_stage = "create-class"
	if _busy:
		_busy = false
		busy_changed.emit(false)


func _on_character_primary_action() -> void:
	if not _creation_active or _busy:
		return
	if _stage_index(_character_stage) < mini(5, int(_character_draft.get("furthest_step", 1))):
		var routes := ["create-class", "create-abilities", "create-origin", "create-equipment", "create-identity", "create-review"]
		_sync_identity_fields()
		_show_creation_route(routes[_stage_index(_character_stage)])
		return
	if _character_stage == "create-equipment" and bool(_character_draft.get("pack_choice_pending", false)):
		return
	if _roll_ready:
		_start_next_roll()
		return
	if _character_stage == "create-class":
		_character_stage = "create-rolling"
		_character_draft["roll_pending"] = true
		_character_draft["roll_failed"] = false
		_show_creation_route(_character_stage)
		_refresh_rolls()
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
		_character_draft["roll_pending"] = str(_character_draft.get("class_id", "classless")) != "classless"
		_show_creation_route(_character_stage)
		if bool(_character_draft.get("roll_pending", false)):
			_refresh_rolls()
	elif _character_stage == "create-origin":
		if _route_blocked(_character_stage):
			return
		_character_stage = "create-equipment"
		_character_draft["equipment_roll_pending"] = true
		_character_draft["equipment_roll_failed"] = false
		_show_creation_route(_character_stage)
		_refresh_rolls()
	elif _character_stage == "create-equipment":
		if bool(_character_draft.get("pack_choice_pending", false)):
			_set_status("Choose a source-defined pack before continuing.")
			return
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
		var preferred: Dictionary = _character_draft.get("preferred_miniature", {})
		if preferred.is_empty():
			_set_status("Choose a published Miniature before continuing.", true)
			return
		_character_stage = "create-review"
		_show_creation_route(_character_stage)
	elif _character_stage == "create-review":
		_sync_identity_fields()
		_commit_character()


func _refresh_rolls() -> void:
	if not _creation_active:
		return
	var step := int(_character_draft.get("furthest_step", 1))
	var pending_key := "equipment_roll_pending" if step == 4 else "roll_pending"
	var failed_key := "equipment_roll_failed" if step == 4 else "roll_failed"
	_next_roll = {}
	_roll_ready = false
	if not bool(_character_draft.get(pending_key, false)) or bool(_character_draft.get(failed_key, false)):
		return
	var terms := _roll_plan.terms(_character_draft, step)
	var complete := true
	for term in terms:
		if not bool(term.complete):
			complete = false
			if _next_roll.is_empty() and bool(term.available) and not _rolling.has(term.name):
				_next_roll = term
	var slot := _roll_plan.scroll_choice(_character_draft) if step == 4 else ""
	var new_choice := not slot.is_empty() and slot != str(_character_draft.get("scroll_choice_slot", ""))
	_character_draft["scroll_choice_slot"] = slot
	if complete and slot.is_empty() and not bool(_character_draft.get("pack_choice_pending", false)):
		_character_draft[pending_key] = false
		if step == 2 and _stage_index(_character_stage) == 2:
			_character_stage = "create-abilities"
		elif step == 4:
			_finalize_equipment()
	else:
		_roll_ready = not _next_roll.is_empty() and slot.is_empty() and not bool(_character_draft.get("pack_choice_pending", false))
	_character_draft["rolling"] = _rolling.duplicate()
	_character_draft["roll_ready"] = _roll_ready
	if not _next_roll.is_empty():
		_character_draft["active_roll"] = str(_next_roll.name)
		_character_draft["active_roll_formula"] = "%dd%d" % [int(_next_roll.count), int(_next_roll.faces)]
	_show_creation_route(_character_stage)
	if new_choice:
		scroll_choice_requested.emit(slot)


func _start_next_roll() -> void:
	if not _roll_ready or _next_roll.is_empty():
		return
	var term := _next_roll.duplicate()
	var step := int(_character_draft.get("furthest_step", 1))
	var token := _creation_generation
	var name := str(term.name)
	_rolling.append(name)
	_refresh_rolls()
	var result: SDK.DiceRollResult = await _automatic_roll(name, int(term.faces), int(term.count), token)
	if token != _creation_generation or not _creation_active:
		return
	var rolling_index := _rolling.find(name)
	if rolling_index >= 0:
		_rolling.remove_at(rolling_index)
	_character_draft["rolling"] = _rolling.duplicate()
	if not result.ok:
		_character_draft["equipment_roll_pending" if step == 4 else "roll_pending"] = false
		_character_draft["equipment_roll_failed" if step == 4 else "roll_failed"] = true
		_roll_ready = false
		_character_draft["roll_ready"] = false
		if _character_stage == "create-rolling":
			_character_stage = "create-abilities"
		_show_creation_route(_character_stage)
		_set_status(result.message, true)
		return
	var total := _roll_total(result, int(term.faces))
	var profile: Dictionary = _character_draft.get("class_profile", {})
	var abilities: Dictionary = _character_draft.get("abilities", {})
	if step == 2:
		if name == "Hit points":
			_character_draft["hit_points_roll"] = total
		else:
			var offsets: Dictionary = profile.get("ability_offsets", {})
			var score := total + int(offsets.get(name, 0))
			abilities[name] = {"score": score, "modifier": _modifier(score)}
			if name == "Agility":
				_character_draft["creation_roll_sequence"] = result.sequence
		if _character_draft.has("hit_points_roll") and abilities.has("Toughness"):
			var toughness: Dictionary = abilities.get("Toughness", {})
			var hp := maxi(1, int(_character_draft.hit_points_roll) + int(toughness.get("modifier", 0)))
			_character_draft["hit_points"] = hp
			_character_draft["maximum_hit_points"] = hp
	elif step == 3:
		_character_draft[str(term.key)] = total
		_refresh_origin()
	else:
		var totals: Dictionary = _character_draft.get("equipment_rolls", {})
		if name != "Armor" or total != 4 or not bool(profile.get("reroll_heavy_armor", false)):
			totals[name] = total
		if name == "Equipment pack":
			_character_draft["pack"] = "Backpack" if total == 3 else ("Sack" if total == 4 else "Nothing")
			_character_draft["pack_choice_pending"] = not _source_definition.pack_choices_for_roll(total).is_empty()
			if bool(_character_draft.pack_choice_pending):
				pack_choice_requested.emit()
				if token != _creation_generation or not _creation_active:
					return
	_refresh_rolls()


func _refresh_origin() -> void:
	var class_id := str(_character_draft.get("class_id", "classless"))
	var traits: Array = []
	for term in _roll_plan.origin_terms(_character_draft):
		if not _character_draft.has(term[2]):
			continue
		var roll := int(_character_draft.get(str(term[2]), 0))
		if term[2] == "origin_roll":
			_character_draft["origin"] = CLASSES.new().origin(class_id, roll)
		elif term[2] == "first_decoction_roll" or term[2] == "second_decoction_roll":
			traits.append(CLASSES.new().decoction(roll))
		elif term[2] != "decoction_doses":
			traits.append(CLASSES.new().feature(class_id, roll))
	_character_draft["traits"] = traits


func _finalize_equipment() -> void:
	var totals: Dictionary = _character_draft.get("equipment_rolls", {})
	var first_roll := int(totals.get("Equipment first", 0))
	var second_roll := int(totals.get("Equipment second", 0))
	_character_draft["equipment_rolls"] = totals
	_character_draft["silver"] = int(totals.get("Silver", 0)) * 10
	_character_draft["omens"] = int(totals.get("Omens", 0))
	var weapon_name: String = _source_definition.resolve_equipment_name("Weapon", int(totals.get("Weapon", 1)))
	var armor_name: String = _source_definition.resolve_equipment_name("Armor", int(totals.get("Armor", 1)))
	var inventory: Array = [
		{"name": "Waterskin", "source_item_id": "waterskin"},
		{"name": "Dried food", "source_item_id": "dried-food", "quantity": int(totals.get("Food", 0))},
	]
	if _character_draft["pack"] != "Nothing":
		inventory.append({"name":
				_character_draft["pack"], "source_item_id": _pack_id(str(_character_draft["pack"]))})
	var first_item := _first_equipment_item(first_roll, totals)
	var second_item := _second_equipment_item(second_roll, totals)
	if not first_item.is_empty() and not _scroll_was_disposed("first"):
		inventory.append(first_item)
	if first_roll == 8:
		inventory.append({"name": "Lockpicks", "source_item_id": "lockpicks"})
	if not second_item.is_empty() and not _scroll_was_disposed("second"):
		inventory.append(second_item)
	if totals.has("Hermit scroll"):
		var sacred := int(totals.get("Hermit scroll family", 0)) == 1
		var hermit_scroll := int(totals.get("Hermit scroll", 0))
		inventory.append(SCROLLS.new().item("sacred" if sacred else "unclean", hermit_scroll))
	var weapon_id := _indexed_item_id(WEAPON_IDS, int(totals.get("Weapon", 0)))
	inventory.append({"name": weapon_name, "source_item_id": weapon_id, "roll": int(totals.get("Weapon", 0)), "kind": "Weapon", "equipped": true})
	var abilities: Dictionary = _character_draft.get("abilities", {})
	var presence: Dictionary = abilities.get("Presence", {})
	var ammunition_quantity := int(presence.get("modifier", 0)) + 10
	if weapon_id == "bow":
		inventory.append({"name": "Arrow", "source_item_id": "arrow", "quantity": ammunition_quantity})
	elif weapon_id == "crossbow":
		inventory.append({"name": "Bolt", "source_item_id": "bolt", "quantity": ammunition_quantity})
	if armor_name != "No armor":
		inventory.append({"name": armor_name, "source_item_id": _indexed_item_id(ARMOR_IDS, int(totals.get("Armor", 0))), "roll": int(totals.get("Armor", 0)), "kind": "Armor", "equipped": true})
	var creature_grants := _starting_creature_grants(second_roll, totals)
	var companion_sheets: Array = []
	var traits: Array = _character_draft.get("traits", [])
	for raw_feature in traits:
		var feature: Dictionary = raw_feature
		if feature.has("item"):
			var feature_source: Dictionary = feature["item"]
			var feature_item: Dictionary = feature_source.duplicate(true)
			feature_item["rules"] = feature.get("rules", "")
			inventory.append(feature_item)
		if feature.has("creature"):
			creature_grants.append({"definition_id": feature["creature"]})
		if str(feature.get("companion", "")) == "descriptive":
			companion_sheets.append({"name": feature.get("name", "Companion"), "source_item_id": feature.get("id", ""), "rules": feature.get("rules", "")})
	if str(_character_draft.get("class_id", "")) == "occult-herbmaster":
		inventory.append({"name": "Portable laboratory", "source_item_id": "portable-laboratory", "quantity": 1, "uses": int(_character_draft.get("decoction_doses", 0)), "rules": "Shared doses for the two generated decoctions. Allocate at the table; unused decoctions lose vitality after 24 hours. Track eligibility and expiry manually."})
	_character_draft["inventory"] = inventory
	_character_draft["companion_sheets"] = companion_sheets
	var starting_creature_ids: Array = _starting_creature_ids_for_grants(creature_grants)
	if starting_creature_ids.size() != creature_grants.size():
		_character_draft["equipment_roll_pending"] = false
		_character_draft["equipment_roll_failed"] = true
		_show_creation_route(_character_stage)
		_set_status("The source requires a combat-profile Creature Actor, but its Package definition is unavailable.", true)
		return
	_character_draft["starting_creature_ids"] = starting_creature_ids
	_character_draft["starting_creature_grants"] = creature_grants
	_character_draft["equipment_roll_pending"] = false
	_character_draft["equipment_roll_failed"] = false
	_show_creation_route(_character_stage)
	_set_status("Starting equipment is ready. Choose a source-defined pack.")


func _scroll_was_disposed(slot: String) -> bool:
	return _roll_plan.scroll_disposed(_character_draft, slot)


func _first_equipment_item(roll: int, totals: Dictionary) -> Dictionary:
	if roll < 1 or roll > FIRST_EQUIPMENT_NAMES.size():
		return {}
	var item := {"name": FIRST_EQUIPMENT_NAMES[roll - 1], "source_item_id": FIRST_EQUIPMENT_IDS[roll - 1]}
	var abilities: Dictionary = _character_draft.get("abilities", {})
	if roll == 2:
		var presence: Dictionary = abilities.get("Presence", {})
		var torch_quantity := int(presence.get("modifier", 0)) + 4
		item["quantity"] = 1 if torch_quantity < 1 else torch_quantity
	if roll == 5:
		var scroll_roll := int(totals.get("Unclean scroll", 0))
		item = SCROLLS.new().item("unclean", scroll_roll)
	if roll == 7:
		var medicine_presence: Dictionary = abilities.get("Presence", {})
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
		item = SCROLLS.new().item("sacred", scroll_roll)
	if roll == 4:
		item["quantity"] = int(totals.get("Monkey count", 0))
	return item


func _starting_creature_grants(roll: int, totals: Dictionary) -> Array:
	var grants: Array = []
	if roll == 3:
		var hp := int(totals["Dog hit points"]) + 2
		grants.append({"definition_id": "dog-small-but-vicious", "hit_points": hp, "maximum_hit_points": hp})
	elif roll == 4:
		for index in range(int(totals.get("Monkey count", 0))):
			var hp := int(totals.get("Monkey %d hit points" % (index + 1), 0)) + 2
			grants.append({"definition_id": "monkey", "hit_points": hp, "maximum_hit_points": hp})
	return grants


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
	var formulas: Dictionary = _character_draft.get("roll_formulas", {})
	formulas[name] = "%dd%d" % [count, faces]
	_character_draft["roll_formulas"] = formulas
	await get_tree().process_frame
	if token != _creation_generation or not _creation_active:
		return SDK.DiceRollResult.new({"ok": false, "message": "Character creation was discarded."})
	# A d2 uses a physical d4, with each face pair mapped to one outcome.
	# Keep the physical result intact; apply the source die conversion when read.
	var physical_faces := 4 if faces == 2 else faces
	var roll_name := name + " (d2: d4 / 2, round up)" if faces == 2 else name
	var request_id := sdk.dice.new_request_id()
	_pending_roll_ids.append(request_id)
	var result: SDK.DiceRollResult = await sdk.dice.roll(SDK.DiceRequest.new([SDK.DiceTerm.new(roll_name, physical_faces, count)], request_id))
	var pending_index := _pending_roll_ids.find(request_id)
	if pending_index >= 0:
		_pending_roll_ids.remove_at(pending_index)
	if token == _creation_generation and _creation_active and result.ok:
		var values: Array[int] = []
		for term in result.terms:
			for value in term.results:
				values.append(int(value))
		var recorded: Dictionary = _character_draft.get("roll_faces", {})
		recorded[name] = values
		_character_draft["roll_faces"] = recorded
	if token == _creation_generation and result.code == "session_ended":
		# Leave accepted values and the unfinished phase available for capture.
		# The suspended coroutine must not mark the retained draft as a rule failure.
		_creation_generation += 1
	return result


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


func _choose_preferred_miniature() -> void:
	if not _creation_active or _character_stage != "create-identity":
		return
	_sync_identity_fields()
	var picker := get_node(^"MiniaturePicker")
	var result := sdk.windows.push(self, picker, _t("Choose Miniature"))
	if not result.ok:
		_set_status(result.message, true)
		return
	picker.open(sdk, i18n, _character_draft.get("preferred_miniature", {}))


func _miniature_selected(reference: Dictionary) -> void:
	if _creation_active and _character_stage == "create-identity":
		_character_draft["preferred_miniature"] = reference.duplicate(true)


func _miniature_picker_closed() -> void:
	if _creation_active and _character_stage == "create-identity":
		_show_creation_route(_character_stage)


func _commit_character() -> void:
	if _busy or not _creation_active or sdk == null or _character_definition == null:
		return
	# An acknowledgement can be lost after durable creation. Reconcile the
	# retained request identity against the fresh shared state before retrying.
	var existing: SDK.ActorListResult = sdk.actors.list()
	if not existing.ok:
		_set_status(existing.message, true)
		return
	for actor in existing.items:
		var data: Dictionary = actor.data
		if str(data.get("schema", "")) == "mork-borg-character/v1" and str(data.get("creation_id", "")) == str(_character_draft.get("creation_id", "")):
			if actor.access_level != "Owner":
				_set_status("The created Character is unavailable for editing.", true)
				return
			_complete_character_creation(actor)
			return
	var token := _creation_generation
	var choices: Dictionary = {
		"creation_id": _character_draft.get("creation_id", ""),
		"creation_roll_sequence": _character_draft.get("creation_roll_sequence", 0),
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
		"origin_roll": _character_draft.get("origin_roll", 0),
		"feature_roll": _character_draft.get("feature_roll", 0),
		"second_feature_roll": _character_draft.get("second_feature_roll", 0),
		"decoction_rolls": [_character_draft.get("first_decoction_roll", 0), _character_draft.get("second_decoction_roll", 0)] if str(_character_draft.get("class_id", "")) == "occult-herbmaster" else [],
		"scroll_dispositions": _character_draft.get("scroll_dispositions", []),
		"preferred_miniature": _character_draft.get("preferred_miniature", {}),
		"companion_sheets": _character_draft.get("companion_sheets", []),
		"starting_creature_ids": _character_draft.get("starting_creature_ids", []),
		"starting_creature_grants": _character_draft.get("starting_creature_grants", []),
	}
	var starting_ids: Array = choices["starting_creature_ids"]
	var starting_grants: Array = choices["starting_creature_grants"]
	for creature_id in starting_ids:
		var creature_id_text: String = creature_id
		if _find_definition(creature_id_text) == null:
			_set_busy(false, "Starting Creature grant %s is unavailable; Character was not created." % creature_id_text, true)
			return
	var child_requests: Array = []
	for creature_index in range(starting_ids.size()):
		var creature_id_text: String = starting_ids[creature_index]
		var creature_definition := _find_definition(creature_id_text)
		if creature_definition == null:
			_set_busy(false, "Starting Creature grant %s is unavailable; Character was not created." % creature_id_text, true)
			return
		var creature_choices: Dictionary = {}
		if creature_index < starting_grants.size():
			var retained_grant: Dictionary = starting_grants[creature_index]
			creature_choices = retained_grant.duplicate(true)
		creature_choices["creation_id"] = choices["creation_id"]
		creature_choices["creation_roll_sequence"] = choices["creation_roll_sequence"]
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
	_complete_character_creation(result.actor)


func _complete_character_creation(actor: SDK.Actor) -> void:
	_creation_active = false
	_rolling.clear()
	_next_roll = {}
	_roll_ready = false
	_character_draft = {}
	_set_busy(false, "Character created with ordinary Owner access.")
	character_created.emit(actor)


func _find_definition(local_id: String) -> SDK.ContentEntry:
	for entry in _definitions:
		if entry.reference.local_id == local_id:
			return entry
	return null


func set_compact(compact: bool) -> void:
	_sync_identity_fields()
	_compact = compact
	if _creation_active:
		_show_creation_route(_character_stage)


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"View").localize(locale)
