extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const I18N = preload(ROOT + "ui/localization.gd")
var _locale := I18N.new()
const CARD = preload(ROOT + "ui/attack_card.gd")
const ACTION = preload(ROOT + "logic/tabletop_action.gd")
const HEALTH = preload(ROOT + "logic/health_action.gd")
const BROKEN = preload(ROOT + "logic/broken_incident.gd")
const SOURCES = preload(ROOT + "logic/attack_sources.gd")
const ITEMS = preload(ROOT + "logic/character_actions.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
const ROOKS = preload(ROOT + "logic/source_rooks.gd")
const AMMO = preload(ROOT + "logic/ammunition.gd")
@onready var card: CARD = get_node("Card")
var _actor: SDK.ActorId
var _rook: SDK.RookId
var _task: Dictionary = {}
var _options: Dictionary = {}
var _item: Dictionary = {}
var _data: Dictionary = {}
var _action: ACTION
var _health: HEALTH
var _dirty := false
var _reading := false
var _closed := true
var _valid_target := false
var _defence_target := false
var _elapsed := 0.0
var _choices_key := ""
var _queued: Array[Dictionary] = []
var _incoming := false
var _range_key := ""

func ready() -> void:
	_locale.bind(sdk)
	card.localize(_locale)
	card.prepare.connect(_prepare)
	card.close_requested.connect(_close)
	card.target_requested.connect(_choose_target)
	card.decision.connect(_decision)
	closed.connect(_cancel)
	if sdk != null:
		sdk.world_changed.connect(_changed)
		sdk.targeting.changed.connect(_targets_changed)

func opened_task(actor: SDK.ActorId, task: Dictionary) -> void:
	if not _closed:
		if bool(task.get("incoming", false)):
			var incoming: Dictionary = task.outcome
			if _action != null and str(_action.snapshot.get("id", "")) == str(incoming.id):
				return
			for queued in _queued:
				var queued_task: Dictionary = queued.get("task", {})
				var queued_outcome: Dictionary = queued_task.get("outcome", {})
				if str(queued_outcome.get("id", "")) == str(incoming.id):
					return
			_queued.append({"actor": actor.value, "task": task.duplicate(true)})
		return
	_closed = false
	visible = true
	_incoming = bool(task.get("incoming", false))
	_choices_key = ""
	card.message("")
	_actor = actor
	_task = task.duplicate(true)
	_options = {"mode": str(task.get("mode", "attack")), "entry": str(task.get("entry", "")), "improvised_mode": "melee", "tabletop": true}
	var resolver := ROOKS.new()
	var selected := sdk.rooks.selected()
	_rook = resolver.resolve(resolver.candidates(sdk, actor), selected.value if selected != null else "")
	if bool(task.get("incoming", false)):
		_new_action()
		_action.adopt(task.outcome)
	_dirty = true

func _process(delta: float) -> void:
	if _closed or sdk == null:
		return
	_elapsed += delta
	if _elapsed >= 0.5:
		_elapsed = 0.0
		_dirty = true
	if _dirty and not _reading:
		_dirty = false
		_refresh()

func _refresh() -> void:
	_reading = true
	if _action != null and str(_action.snapshot.get("defender", "")) == sdk.context().participant_id:
		_actor = SDK.ActorId.new(str(_action.snapshot.target))
	var source := sdk.actors.read(_actor)
	if not source.ok or source.actor.access_level != "Owner":
		_reading = false
		_close()
		return
	_data = source.actor.data
	var device := sdk.presentation_experience()
	card.responsive("phone" if device.is_phone else "tablet" if device.is_tablet else "desktop")
	if _health != null:
		if _health.state == "resolved":
			_reading = false
			_close()
			return
		card.identity(str(_data.get("name", "")), "Broken", "")
		card.message(_health.message)
		card.consequence("Done" if not _health.pending else "", "")
		visible = not _health.pending
		_reading = false
		return
	var outcome: Dictionary = _action.snapshot if _action != null else {}
	if _action != null and _action.state not in ["ready", "error"] or not str(outcome.get("defender", "")).is_empty():
		_present_outcome(outcome)
		visible = not _closed and (_action.state != "pending")
		_reading = false
		return
	var creature := str(_data.get("schema", "")) == "mork-borg-adversary/v1"
	var items: Array = CREATURES.new().combat_attacks(_data) if creature else ITEMS.new(sdk, _actor).inventory(_data)
	_item = SOURCES.new().intrinsic(_data, str(_task.get("item", "")), _options)
	for raw in items:
		var item: Dictionary = raw
		if str(item.get("inventory_id", "")) == str(_task.get("item", "")):
			_item = item
	var reach := float(_item.get("range_feet", 0))
	var range_key := (_rook.value + ":" + str(reach)) if _rook != null and reach > 0 else ""
	if range_key != _range_key:
		if range_key.is_empty():
			sdk.targeting.end_range()
			_range_key = ""
		elif sdk.targeting.begin_range(_rook, reach * 0.3048, _locale.text("%d ft") % int(reach)).ok:
			_range_key = range_key

	var ability_name := "Agility" if str(_task.get("mode", "")) == "jab" else str(_item.get("attack_ability", "Strength"))
	var abilities: Dictionary = _data.get("abilities", {})
	var ability: Dictionary = abilities.get(ability_name, {})
	var modifier := int(ability.get("modifier", 0))
	card.identity(str(_data.get("name", "")), str(_item.get("name", "Choose weapon")), (_locale.text("%s · %d ft") % [_locale.text(ability_name), int(reach)]) if not creature else _locale.text("%d ft") % int(reach))
	await _target(reach, creature)
	if _closed:
		_reading = false
		return
	var available := SOURCES.new().usable(_item, creature)
	var ammo_kind := str(_item.get("ammunition", ""))
	if not ammo_kind.is_empty():
		var candidates := AMMO.new().available(items, ammo_kind)
		_options["ammunition"] = str(candidates[0].inventory_id) if not candidates.is_empty() else ""
		available = available and not candidates.is_empty()
	(card.body.get_node("Decision") as Control).visible = false
	card.combat("1d20" + (" %+d" % modifier if modifier != 0 else ""), str(_item.get("damage", "")), available and _valid_target)
	if creature and _defence_target:
		card.combat("", str(_item.get("damage", "")), available and _valid_target, "Defence")
		card.request_defence(available and _valid_target)
	card.message(_action.message if _action != null else "", _action != null and _action.state == "error")
	_choices(items)
	_reading = false

func _target(reach: float, creature: bool) -> void:
	_valid_target = false
	_defence_target = creature
	var result := await sdk.targeting.snapshot()
	if not result.ok or result.snapshot.rooks.size() != 1 or _rook == null:
		card.target("Choose a target", "", false, true)
		return
	var target: SDK.RookId = result.snapshot.rooks[0]
	var identity := sdk.public_identities.read(target)
	var distance := sdk.scenes.distance(_rook, target)
	var rook := sdk.rooks.read(target)
	var schema := ""
	if rook.ok and rook.rook.actor != null:
		var actor := sdk.actors.read(rook.rook.actor)
		if actor.ok:
			schema = str(actor.actor.data.get("schema", ""))
			_defence_target = schema == "mork-borg-character/v1"
			if creature and schema == "mork-borg-adversary/v1":
				var access := sdk.actors.access(actor.actor.id)
				if access.ok:
					for entry in access.items:
						_defence_target = _defence_target or entry.access_level == "Owner"
	_valid_target = distance.ok and distance.distance <= reach * 0.3048 + 0.000001 and target.value != _rook.value and (schema == "mork-borg-adversary/v1" or creature and schema == "mork-borg-character/v1")
	var name := identity.public_identity.label if identity.ok else "Creature"
	card.target(name, _locale.text("%.1f ft") % (distance.distance / 0.3048) if distance.ok else "", _valid_target, true)

func _choices(items: Array) -> void:
	var owners: Array = _action.snapshot.get("owners", []) if _action != null else []
	var key := str(_task.get("item", "")) + ":" + str(_rook.value if _rook != null else "") + str(owners)
	if key == _choices_key:
		return
	_choices_key = key
	var choices: VBoxContainer = card.body.get_node("Choices")
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	if not owners.is_empty():
		var owner_picker := OptionButton.new()
		owner_picker.theme_type_variation = "RookframeActionSelect"
		owner_picker.custom_minimum_size = Vector2(0, 44)
		owner_picker.add_item(_locale.text("Choose defending Player"))
		for index in range(owners.size()):
			var owner: Dictionary = owners[index]
			owner_picker.add_item(str(owner.name))
		owner_picker.item_selected.connect(_owner_selected.bind(owners))
		choices.add_child(owner_picker)
	var rooks := ROOKS.new().candidates(sdk, _actor)
	if _rook == null and rooks.size() > 1:
		var picker := OptionButton.new()
		picker.theme_type_variation = "RookframeActionSelect"
		picker.custom_minimum_size = Vector2(0, 44)
		picker.add_item(_locale.text("Choose source Rook"))
		for index in range(rooks.size()):
			picker.add_item("Rook %d" % (index + 1))
		picker.item_selected.connect(_source_selected.bind(rooks))
		choices.add_child(picker)
	if str(_task.get("mode", "")) == "jab":
		var weapons := SOURCES.new().jab_weapons(items)
		var picker := OptionButton.new()
		picker.theme_type_variation = "RookframeActionSelect"
		picker.custom_minimum_size = Vector2(0, 44)
		picker.add_item(_locale.text("Choose a light weapon"))
		for index in range(weapons.size()):
			picker.add_item(str(weapons[index].name))
			if str(weapons[index].inventory_id) == str(_task.get("item", "")):
				picker.select(index + 1)
		picker.item_selected.connect(_weapon_selected.bind(weapons))
		choices.add_child(picker)
	if str(_task.get("item", "")) == "intrinsic:improvised":
		var object_name := LineEdit.new()
		object_name.theme_type_variation = "RookframeActionTextField"
		object_name.accessibility_name = _locale.text("Improvised object")
		object_name.placeholder_text = _locale.text("Improvised object")
		object_name.custom_minimum_size = Vector2(0, 44)
		object_name.text_changed.connect(_object_changed)
		choices.add_child(object_name)
		var mode := OptionButton.new()
		mode.theme_type_variation = "RookframeActionSelect"
		mode.custom_minimum_size = Vector2(0, 44)
		mode.add_item(_locale.text("Melee"))
		mode.add_item(_locale.text("Ranged"))
		mode.item_selected.connect(_mode_selected)
		choices.add_child(mode)
	var special := str(_item.get("source_item_id", ""))
	if str(_task.get("mode", "")) == "jab" or special in ["shoe-of-deaths-horse", "sacred-shepherds-crook", "eurekia"]:
		_check(choices, "Requirements confirmed", "eligible")
	if special == "shoe-of-deaths-horse":
		_check(choices, "Small or medium target", "small_medium")
	if special == "sacred-shepherds-crook":
		_check(choices, "Faithless human", "faithless_human")
	choices.visible = choices.get_child_count() > 0

func _check(parent: VBoxContainer, text: String, key: String) -> void:
	var button := CheckBox.new()
	button.text = _locale.text(text)
	button.custom_minimum_size = Vector2(0, 44)
	button.button_pressed = bool(_options.get(key, false))
	button.toggled.connect(_option_toggled.bind(key))
	parent.add_child(button)

func _prepare() -> void:
	if _action != null and not str(_action.snapshot.get("defender", "")).is_empty():
		await _action.roll({})
		return
	if _reading or _closed or not _valid_target:
		return
	if _action != null:
		await _action.retire()
	_new_action()
	var input := _options.duplicate(true)
	input["item"] = str(_task.get("item", ""))
	input["source"] = _actor.value
	input["rook"] = _rook.value if _rook != null else ""
	sdk.targeting.end_range()
	_range_key = ""
	await _action.attack(input, str(_data.get("schema", "")) == "mork-borg-adversary/v1")
	_dirty = true

func _present_outcome(outcome: Dictionary) -> void:
	if not _incoming:
		sdk.targeting.end_range()
		_range_key = ""
	(card.body.get_node("Choices") as Control).visible = false
	(card.body.get_node("Decision") as Control).visible = false
	var state := str(outcome.get("state", "pending"))
	var defender := str(outcome.get("defender", "")) == sdk.context().participant_id
	if state == "resolved":
		# Results are already committed to the Action Log. Only retain a required roll.
		if _needs_broken():
			card.identity(str(_data.get("name", "")), "Broken", "")
			card.message("")
			card.consequence("Roll Broken", "")
		else:
			_close()
	elif state == "ready" and defender:
		card.identity(str(outcome.get("character", "")), "Defend", str(outcome.get("attacker", "")), true)
		var modifier := int(outcome.get("agility", 0))
		if bool(outcome.get("automatic_hit", false)):
			card.consequence("Roll damage", "")
		else:
			card.combat("1d20" + (" %+d" % modifier if modifier != 0 else ""), str(outcome.get("damage", "")), true, "Defence", true)
		card.show_target(false)
		card.message("")
	elif state == "shield":
		card.identity(str(outcome.get("character", "")), "Shield", str(outcome.get("attack", "")), true)
		card.message("Break your shield to prevent all damage from this attack." if defender else "Waiting for the defending Player")
		card.consequence((_locale.text("Take %d damage") % int(outcome.get("loss", 0))) if defender else "", "Break shield")
		(card.body.get_node("Decision/Second") as Control).theme_type_variation = "RookframePrimaryButton"
	elif state == "fumble":
		card.identity(str(outcome.get("character", "")), "Fumble", str(outcome.get("weapon", "")))
		card.message("" if sdk.context().is_gm else "Waiting for the GM")
		card.consequence("Broken" if sdk.context().is_gm else "", "Lost")
	else:
		card.message("Waiting for the defending Player" if state == "ready" else str(outcome.get("message", "")))
		card.consequence("Done" if state == "ended" else "", "")

func _needs_broken() -> bool:
	if str(_data.get("schema", "")) != "mork-borg-character/v1" or int(_data.get("hit_points", 1)) != 0:
		return false
	var broken := BROKEN.new()
	var incident: Dictionary = _data.get("broken_incident", {})
	return not broken.is_dead(_data) and (int(incident.get("outcome", 0)) == 0 or broken.can_complete_followup(_data))

func _decision(index: int) -> void:
	if _action == null or _action.state in ["ready", "error"]:
		await _prepare()
		return
	if _action != null and _action.state == "shield":
		await _action.choose("take" if index == 0 else "break")
	elif _action != null and _action.state == "fumble":
		await _action.choose("break" if index == 0 else "lose")
	elif _health == null and _needs_broken():
		var health := HEALTH.new(sdk)
		add_child(health)
		health.changed.connect(_changed)
		_health = health
		await _health.start({"source": _actor.value, "kind": "broken"})
	else:
		_close()
	_dirty = true

func _choose_target() -> void:
	sdk.targeting.choose()

func _targets_changed(_snapshot: SDK.TargetSnapshot) -> void:
	_dirty = true

func _changed() -> void:
	# Keep the authored surface folded throughout the Throw and its authority
	# acknowledgement. Only a real decision should bring it back onto the table.
	if (_action != null and _action.state == "pending") or (_health != null and _health.pending):
		visible = false
	_dirty = true

func _close() -> void:
	var surface := "tabletop_consequence_surface.tres" if _incoming else "tabletop_attack_surface.tres"
	var queued := _queued
	_queued = []
	_cancel()
	if not queued.is_empty():
		var next: Dictionary = queued[0]
		queued.remove_at(0)
		_queued = queued
		var next_task: Dictionary = next.get("task", {})
		opened_task(SDK.ActorId.new(str(next.actor)), next_task)
	else:
		sdk.windows.close(load(ROOT + "ui/" + surface))

func _cancel() -> void:
	_closed = true
	for queued in _queued:
		var queued_task: Dictionary = queued.get("task", {})
		var outcome: Dictionary = queued_task.get("outcome", {})
		sdk.system_actions.submit(str(outcome.get("operation", "defence")) + ".cancel", {"id": str(outcome.id)})
	_queued.clear()
	if sdk != null and not _incoming:
		sdk.targeting.end_range()
	_range_key = ""
	if _action != null:
		_action.retire()
		_action = null
	if _health != null:
		_health.retire()
		_health = null

func _exit_tree() -> void:
	_cancel()

func _new_action() -> void:
	var action := ACTION.new(sdk)
	add_child(action)
	action.changed.connect(_changed)
	_action = action

func _owner_selected(index: int, owners: Array) -> void:
	var owner: Dictionary = owners[index - 1] if index > 0 else {}
	_options["owner"] = str(owner.get("id", ""))
	_dirty = true

func _source_selected(index: int, rooks: Array[SDK.RookId]) -> void:
	_rook = rooks[index - 1] if index > 0 else null
	_dirty = true

func _weapon_selected(index: int, weapons: Array) -> void:
	if index > 0:
		var weapon: Dictionary = weapons[index - 1]
		_task["item"] = str(weapon.inventory_id)
		_dirty = true

func _object_changed(value: String) -> void:
	_options["object"] = value

func _mode_selected(index: int) -> void:
	_options["improvised_mode"] = "ranged" if index == 1 else "melee"
	_dirty = true

func _option_toggled(value: bool, key: String) -> void:
	_options[key] = value
