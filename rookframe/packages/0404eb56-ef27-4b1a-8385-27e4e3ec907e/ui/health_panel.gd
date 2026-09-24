extends VBoxContainer
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const CHECK = preload("res://rookframe/ui/icons/check.svg")
const ACTION = preload(ROOT + "logic/health_action.gd")
const ROLL_ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_creation_roll.gd")
const SCROLLS = preload(ROOT + "logic/starting_scrolls.gd")
signal action_created(action: ACTION)
signal navigate_requested(route: String, item: String)
signal workflow_changed(route: String, title: String, can_submit: bool, busy: bool)
var _sdk: SDK
var _actor: SDK.Actor
var _route := "rest"
var _action: ACTION
var _update_pending := false
var _scroll := ""
var _scroll_family := ""
var _terminal_shown := false
@onready var _hp_row: ROLL_ROW = get_node(^"Columns/Task/Improvement/MoreHP")
@onready var _debris_row: ROLL_ROW = get_node(^"Columns/Task/Improvement/Debris")
@onready var _ability_row: ROLL_ROW = get_node(^"Columns/Task/Improvement/Abilities")

func _ready() -> void:
	resized.connect(_layout)
	get_node(^"Columns/Context/Content/Authorize").pressed.connect(_authorize)
	get_node(^"Columns/Task/Rest/Content/Breath").toggled.connect(_rest_changed)
	get_node(^"Columns/Task/Rest/Content/Sleep").toggled.connect(_rest_changed)
	_rest_changed(true)

func _rest_changed(_pressed: bool) -> void:
	var breath: Button = get_node(^"Columns/Task/Rest/Content/Breath")
	var sleep: Button = get_node(^"Columns/Task/Rest/Content/Sleep")
	for choice in [breath, sleep]:
		choice.icon = CHECK if choice.button_pressed else null
		choice.accessibility_description = "Selected" if choice.button_pressed else "Not selected"

func configure(actor: SDK.Actor, facade: SDK, route: String) -> void:
	_actor = actor
	_sdk = facade
	_route = route
	if not _sdk.world_changed.is_connected(_changed):
		_sdk.world_changed.connect(_changed)
	_render()

func _render() -> void:
	var data: Dictionary = _actor.data
	var state := _action.state if _action != null else "ready"
	var editing := state in ["ready", "error"]
	var terminal := state in ["resolved", "ended"]
	var improve := _route == "improve"
	var title: String = {"rest": "Rest", "improve": "Getting better", "broken": "Broken & death"}.get(_route, "Recovery")
	if terminal:
		title = "Action ended" if state == "ended" else ("Improvement resolved" if improve else "Recovery resolved" if _route == "rest" else "Broken & death")
	get_node(^"Columns").visible = not terminal
	get_node(^"Result").visible = terminal
	get_node(^"Columns/Task/Rest").visible = _route == "rest"
	get_node(^"Columns/Task/Improvement").visible = improve
	get_node(^"Columns/Task/Broken").visible = _route == "broken"
	get_node(^"Columns/Context/Content/Heading").text = "WHEN THE GM DECIDES" if improve else "BEFORE ROLLING"
	get_node(^"Columns/Context/Content/Copy").text = "Begin after the GM grants an improvement. Resolve each step in order." if improve else ("The table establishes that this rest has happened. Without food or drink, or while infected, resting restores no HP." if _route == "rest" else "At zero HP, roll Broken. Negative HP means dead. Delayed recovery and other timed consequences are handled by the table.")
	get_node(^"Columns/Context/Content/Values").text = "Current hit points\n%s / %s" % [str(data.get("hit_points", 0)), str(data.get("maximum_hit_points", 0))]
	if improve:
		var abilities: Dictionary = data.get("abilities", {})
		var labels := ""
		for key in ["Agility", "Presence", "Strength", "Toughness"]:
			var ability: Dictionary = abilities.get(key, {})
			var modifier: int = ability.get("modifier", 0)
			labels += (" · " if not labels.is_empty() else "") + "%s %+d" % [key, modifier]
		get_node(^"Columns/Context/Content/Values").text = "Maximum HP · %s\n%s" % [str(data.get("maximum_hit_points", 0)), labels]
	get_node(^"Columns/Context/Content/Eligible").visible = not improve and editing
	get_node(^"Columns/Context/Content/Restrictions").visible = _route == "rest" and editing
	get_node(^"Columns/Task/Rest/Content/Breath").disabled = not editing
	get_node(^"Columns/Task/Rest/Content/Sleep").disabled = not editing
	var authorized := not str(data.get("improvement_grant", "")).is_empty()
	get_node(^"Columns/Context/Content/Authorize").visible = improve and editing and _sdk.context().is_gm and not authorized
	get_node(^"Columns/Context/Content/Authorization").visible = improve and editing
	get_node(^"Columns/Context/Content/Authorization").text = "GM authorization received." if authorized else "Waiting for the GM to authorize improvement."
	get_node(^"Scrolls").visible = state == "scroll"
	if state == "scroll":
		var family := str(_action.snapshot.get("family", ""))
		if family != _scroll_family:
			_scroll_family = family
			var options: Array = SCROLLS.TABLES.get(family, [])
			for index in range(options.size()):
				var entry: Dictionary = options[index]
				var button := get_node(^"Scrolls/Choices").get_child(index) as Button
				button.text = str(entry.name)
				button.pressed.connect(_choose_scroll.bind(str(entry.source_item_id)))
	get_node(^"Specialties").visible = state == "specialties"
	if state == "specialties":
		var traits: Array = _action.snapshot.get("specialties", [])
		for index in range(traits.size()):
			var entry: Dictionary = traits[index]
			(get_node(^"Specialties/Choices").get_child(index) as Button).text = "Reroll " + str(entry.get("name", "specialty"))
	var outcome := _action.message if _action != null else ""
	get_node(^"Outcome").text = outcome
	get_node(^"Outcome").visible = not outcome.is_empty() and not terminal
	get_node(^"Result/Content/Heading").text = title.to_upper()
	get_node(^"Result/Content/Copy").text = outcome
	if terminal and not _terminal_shown:
		get_node(^"Result/Content/Heading").grab_focus()
	_terminal_shown = terminal
	get_node(^"Outcome").theme_type_variation = "RookframeError" if state == "error" else "RookframeMeta"
	var can_submit := state in ["resolved", "ended", "scroll", "specialties"] or (editing and _actor.access_level == "Owner" and (not improve or authorized))
	workflow_changed.emit(_route, title, can_submit, state == "pending")
	_layout()

func _layout() -> void:
	var compact := size.x < 600
	get_node(^"Columns").vertical = compact
	var phase := str(_action.snapshot.get("phase", "more_hp")) if _action != null else "more_hp"
	var step := 0 if phase in ["more_hp", "hp_increase"] else (1 if phase in ["debris", "silver"] else 2)
	var titles := ["More HP", "Debris", "Ability changes"]
	var formulas := ["6d10 against maximum HP", "d6", "d6 against each ability"]
	var rows: Array[ROLL_ROW] = [_hp_row, _debris_row, _ability_row]
	for index in range(3):
		var status := "complete" if index < step else ("current" if index == step else "locked")
		if _action != null and _action.state == "pending" and index == step:
			status = "pending"
		var row: ROLL_ROW = rows[index]
		row.present_roll(titles[index], formulas[index], "—", status, index + 1, compact)

func submit() -> void:
	if _action != null:
		if _action.state in ["resolved", "ended"]:
			navigate_requested.emit("character", "")
			return
		if _action.state == "scroll":
			await _action.choose({"scroll": _scroll})
			return
		if _action.state == "specialties":
			var selected: Array[int] = []
			for index in range(2):
				if (get_node(^"Specialties/Choices").get_child(index) as Button).button_pressed:
					selected.append(index)
			await _action.choose({"reroll": selected})
			return
		if _action.pending:
			return
		_action.retire()
	var action := ACTION.new(_sdk)
	action_created.emit(action)
	_action = action
	_action.changed.connect(_changed)
	await _action.start({"source": _actor.id.value, "kind": _route, "eligible": _route == "improve" or get_node(^"Columns/Context/Content/Eligible").button_pressed, "rest": "sleep" if get_node(^"Columns/Task/Rest/Content/Sleep").button_pressed else "breath", "food_and_drink": get_node(^"Columns/Context/Content/Restrictions/Food").button_pressed, "infected": get_node(^"Columns/Context/Content/Restrictions/Infected").button_pressed})

func _authorize() -> void:
	get_node(^"Columns/Context/Content/Authorize").disabled = true
	var result := await _sdk.system_actions.submit("health.start", {"id": _sdk.dice.new_request_id(), "source": _actor.id.value, "kind": "authorize", "eligible": true})
	get_node(^"Columns/Context/Content/Authorize").disabled = false
	if not result.ok or str(result.value.get("state", "error")) != "resolved":
		get_node(^"Outcome").text = result.message if not result.ok else str(result.value.message)
		get_node(^"Outcome").visible = true
		get_node(^"Outcome").theme_type_variation = "RookframeError"
		return
	_changed()

func primary_text() -> String:
	var state := _action.state if _action != null else "ready"
	if state in ["resolved", "ended"]:
		return "Done"
	if state == "scroll":
		return "Choose scroll"
	if state == "specialties":
		return "Confirm specialties"
	if state == "pending":
		return "Waiting…"
	if _route == "improve":
		return "Roll 6d10"
	if _route == "broken":
		var data: Dictionary = _actor.data
		var hp: int = data.get("hit_points", 0)
		return "Report death" if hp < 0 else "Roll Broken"
	return "Roll recovery"

func _changed() -> void:
	_update_pending = true
func _process(_delta: float) -> void:
	if _update_pending:
		_update_pending = false
		var latest := _sdk.actors.read(_actor.id)
		if latest.ok:
			_actor = latest.actor
		_render()
func _choose_scroll(id: String) -> void:
	_scroll = id
func close_action() -> void:
	if _action != null:
		_action.cancel()
func _exit_tree() -> void:
	close_action()
