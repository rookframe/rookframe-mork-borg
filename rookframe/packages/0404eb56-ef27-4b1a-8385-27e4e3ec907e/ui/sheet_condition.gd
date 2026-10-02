extends VBoxContainer
const BROKEN = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/broken_incident.gd")
const MUTED := Color(0.568627, 0.6, 0.603922, 1)
signal event_requested(operation: String)
signal broken_requested
signal edit_hp_requested

func _ready() -> void:
	resized.connect(_resize)
	_resize()
	get_node(^"Main/Frame/Inset/Content/Footer/Broken").pressed.connect(_broken)
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Controls/Next").pressed.connect(_event.bind("next"))
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Controls/Undo").pressed.connect(_event.bind("undo"))
	get_node(^"Main/Frame/Inset/Content/Footer/Recover").pressed.connect(_event.bind("recover"))
	get_node(^"Main/Frame/Inset/Content/Footer/Treat").pressed.connect(_event.bind("treat"))
	get_node(^"Main/Frame/Inset/Content/Footer/UndoDeath").pressed.connect(_event.bind("undo"))
	get_node(^"Main/Frame/Inset/Content/Footer/EditHP").pressed.connect(_edit_hp)

func _edit_hp() -> void:
	edit_hp_requested.emit()

func _broken() -> void:
	broken_requested.emit()

func _event(operation: String) -> void:
	event_requested.emit(operation)

func configure(data: Dictionary, condition: Dictionary, enabled: bool) -> void:
	var incident: Dictionary = data.get("broken_incident", {})
	var outcome := int(incident.get("outcome", 0))
	var elapsed := int(incident.get("elapsed", 0))
	var duration := int(incident.get("duration", 0))
	var complete := incident.has("followup_sequence")
	var dead := BROKEN.new().is_dead(data)
	var rounds: bool = complete and outcome in [1, 2] and not incident.get("recovered", false) and not dead
	var bleeding: bool = complete and outcome == 3 and not incident.get("treated", false) and not dead
	var treated: bool = outcome == 3 and incident.get("treated", false) and not dead
	var initial := outcome == 0 and not dead
	var followup := BROKEN.new().can_complete_followup(data)
	get_node(^"Main/Frame/Inset/Content/Header/Caption").text = "Death" if dead else "Broken · unresolved" if initial else "Broken · retained outcome" if followup else "Broken · resolved outcome"
	get_node(^"Main/Frame/Inset/Content/Header/Title").text = str(condition.get("title", "")).capitalize()
	get_node(^"Main/Frame/Inset/Content/Header/Copy").visible = not dead
	get_node(^"Main/Frame/Inset/Content/TopSpacer").visible = dead or rounds or bleeding or treated
	get_node(^"Main/Frame/Inset/Content/Header/Copy").text = str(condition.get("copy", ""))
	get_node(^"Main/Frame/Inset/Content/Outcomes").visible = initial
	get_node(^"Main/Frame/Inset/Content/Counter").visible = rounds or bleeding
	get_node(^"Main/Frame/Inset/Content/Counter/Value/Amount/Number").text = str(maxi(0, duration - elapsed))
	get_node(^"Main/Frame/Inset/Content/Counter/Value/Amount/Hours").visible = bleeding
	get_node(^"Main/Frame/Inset/Content/Treated").visible = treated
	get_node(^"Main/Frame/Inset/Content/Footer/EditHP").visible = treated
	get_node(^"Main/Frame/Inset/Content/Footer/EditHP").disabled = not enabled
	get_node(^"Main/Frame/Inset/Content/Footer/Note").visible = not treated
	get_node(^"Main/Frame/Inset/Content/Counter/Value/Units").text = "rounds remaining" if rounds else "until death unless treated"
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Pips").visible = rounds
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Rules").visible = bleeding
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Controls/Next").text = "Next round" if rounds else "Advance 1 hour"
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Controls/Next").disabled = not enabled or elapsed >= duration
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Controls/Undo").disabled = not enabled or elapsed == 0
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Controls/Undo").tooltip_text = "Undo last round" if rounds else "Undo last hour"
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Controls/Undo").accessibility_name = "Undo last round" if rounds else "Undo last hour"
	for index in range(4):
		var pip = get_node([^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip1", ^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip2", ^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip3", ^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip4"][index])
		pip.visible = index < duration
		get_node([^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip1/Number", ^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip2/Number", ^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip3/Number", ^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip4/Number"][index]).text = str(index + 1)
		get_node([^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip1/Number", ^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip2/Number", ^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip3/Number", ^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip4/Number"][index]).add_theme_color_override("font_color", MUTED if index < elapsed else Color(1, 1, 1, 1))
		pip.get_node(^"Elapsed").visible = index < elapsed
		pip.get_node(^"Strike").visible = index < elapsed
		pip.accessibility_name = "Round %d · %s" % [index + 1, "elapsed" if index < elapsed else "remaining"]
	get_node(^"Main/Frame/Inset/Content/Death").visible = dead
	get_node(^"Main/Frame/Inset/Content/Death/Copy").text = str(condition.get("copy", ""))
	get_node(^"Main/Frame/Inset/Content/Footer/Broken").visible = initial or followup
	get_node(^"Main/Frame/Inset/Content/Footer/Broken").text = "Roll Broken d4" if initial else "Complete Broken dice"
	get_node(^"Main/Frame/Inset/Content/Footer/Broken").disabled = not enabled
	get_node(^"Main/Frame/Inset/Content/Footer/Recover").visible = rounds
	get_node(^"Main/Frame/Inset/Content/Footer/Recover").text = "Awaken" if outcome == 1 else "Recover"
	get_node(^"Main/Frame/Inset/Content/Footer/Recover").disabled = not enabled or elapsed < duration
	get_node(^"Main/Frame/Inset/Content/Footer/Treat").visible = bleeding
	get_node(^"Main/Frame/Inset/Content/Footer/Treat").disabled = not enabled
	get_node(^"Main/Frame/Inset/Content/Footer/UndoDeath").visible = dead and outcome == 3 and complete and elapsed > 0 and not incident.get("negative_hp", false)
	get_node(^"Main/Frame/Inset/Content/Footer/UndoDeath").disabled = not enabled
	get_node(^"Main/Frame/Inset/Content/Footer/Note").text = "%d HP is restored when recovery is due." % mini(int(data.get("maximum_hit_points", 1)), int(incident.get("recovery_hp", 0))) if rounds else "Treatment stops the deadline; it does not add HP." if bleeding else "At exactly 0 HP · Broken d4" if initial else "No further Broken roll." if dead else "Accepted results remain on the sheet."
	get_node(^"Results").visible = incident.has("roll_sequence")
	_result("Broken", true, "Broken", "d4: %d" % outcome)
	_result("Injury", complete and outcome == 2, "Injury", "d6: %d · %s" % [int(incident.get("injury_roll", 0)), str(incident.get("injury", ""))])
	_result("Duration", complete and outcome in [1, 2, 3], "Hemorrhage" if treated else "Deadline" if outcome == 3 else "Duration", "Treated" if treated else "d%d: %d %s" % [2 if outcome == 3 else 4, duration, "hours" if outcome == 3 else "rounds"])
	_result("Recovery", complete and outcome in [1, 2], "Recovery", "d4: %d HP" % int(incident.get("recovery_hp", 0)))
	_result("Elapsed", complete and outcome == 3 and not treated, "Elapsed", "%d hours" % elapsed)

func _result(key: String, shown: bool, caption: String, value: String) -> void:
	var row = get_node({"Broken": ^"Results/Inset/Values/Broken", "Injury": ^"Results/Inset/Values/Injury", "Duration": ^"Results/Inset/Values/Duration", "Recovery": ^"Results/Inset/Values/Recovery", "Elapsed": ^"Results/Inset/Values/Elapsed"}.get(key, ^"Results/Inset/Values/Broken"))
	row.visible = shown
	get_node({"Broken": ^"Results/Inset/Values/Broken/Caption", "Injury": ^"Results/Inset/Values/Injury/Caption", "Duration": ^"Results/Inset/Values/Duration/Caption", "Recovery": ^"Results/Inset/Values/Recovery/Caption", "Elapsed": ^"Results/Inset/Values/Elapsed/Caption"}.get(key, ^"Results/Inset/Values/Broken/Caption")).text = caption
	get_node({"Broken": ^"Results/Inset/Values/Broken/Value", "Injury": ^"Results/Inset/Values/Injury/Value", "Duration": ^"Results/Inset/Values/Duration/Value", "Recovery": ^"Results/Inset/Values/Recovery/Value", "Elapsed": ^"Results/Inset/Values/Elapsed/Value"}.get(key, ^"Results/Inset/Values/Broken/Value")).text = value

func _resize() -> void:
	var phone := get_viewport_rect().size.y <= 560
	var tablet := get_viewport_rect().size.x <= 1150 and not phone
	size_flags_vertical = 3 if phone else 1
	add_theme_constant_override("separation", 6 if phone else 18)
	get_node(^"Main/Frame/Inset/Content").add_theme_constant_override("separation", 8 if phone else 14 if tablet else 20)
	get_node(^"Main/Frame/Inset/Content/Header").add_theme_constant_override("separation", 3 if phone else 6 if tablet else 12)
	for edge in ["left", "right", "top", "bottom"]:
		get_node(^"Main/Frame/Inset").add_theme_constant_override("margin_" + edge, (12 if edge in ["left", "right"] else 10) if phone else 16 if tablet else 32)
		get_node(^"Results/Inset").add_theme_constant_override("margin_" + edge, (8 if edge in ["left", "right"] else 5) if phone else 12 if tablet else (20 if edge in ["left", "right"] else 14))
	get_node(^"Main/Frame/Inset/Content/Header/Caption").add_theme_font_size_override("font_size", 11 if phone else 14 if tablet else 14)
	get_node(^"Main/Frame/Inset/Content/Header/Title").add_theme_font_size_override("font_size", 25 if phone else 32 if tablet else 48)
	get_node(^"Main/Frame/Inset/Content/Header/Copy").add_theme_font_size_override("font_size", 12 if phone else 16 if tablet else 18)
	get_node(^"Main/Frame/Inset/Content/Counter/Value/Amount/Number").add_theme_font_size_override("font_size", 54 if phone else 72 if tablet else 96)
	get_node(^"Main/Frame/Inset/Content/Counter/Value/Amount/Hours").add_theme_font_size_override("font_size", 26 if phone else 40)
	get_node(^"Main/Frame/Inset/Content/Treated").add_theme_constant_override("separation", 8 if phone else 18)
	get_node(^"Main/Frame/Inset/Content/Treated/Title").add_theme_font_size_override("font_size", 23 if phone else 30)
	get_node(^"Main/Frame/Inset/Content/Treated/Copy").add_theme_font_size_override("font_size", 12 if phone else 16 if tablet else 18)
	get_node(^"Main/Frame/Inset/Content/Counter/Value/Units").add_theme_font_size_override("font_size", 12 if phone else 15 if tablet else 18)
	get_node(^"Main/Frame/Inset/Content/Footer/Note").add_theme_font_size_override("font_size", 12 if phone else 14 if tablet else 16)
	get_node(^"Main/Frame/Inset/Content/Death/Copy").add_theme_font_size_override("font_size", 12 if phone else 16 if tablet else 18)
	get_node(^"Main/Frame/Inset/Content/Death/Mark").custom_minimum_size = Vector2(65, 70) if phone else Vector2(100, 115) if tablet else Vector2(130, 150)
	get_node(^"Main/Frame/Inset/Content/Counter/Value").add_theme_constant_override("separation", 4 if phone else 8)
	get_node(^"Main/Frame/Inset/Content/Counter").add_theme_constant_override("separation", 16 if phone or tablet else 24)
	get_node(^"Main/Frame/Inset/Content/Outcomes").add_theme_constant_override("h_separation", 16 if phone else 12 if tablet else 32)
	get_node(^"Main/Frame/Inset/Content/Outcomes").add_theme_constant_override("v_separation", 6 if phone else 12 if tablet else 20)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome1").add_theme_constant_override("separation", 8 if phone or tablet else 16)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome1/Number").custom_minimum_size = Vector2(24 if phone else 30 if tablet else 44, 0)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome1/Number").add_theme_font_size_override("font_size", 27 if phone else 32 if tablet else 40)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome1/Words/Title").add_theme_font_size_override("font_size", 16 if phone else 19 if tablet else 22)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome1/Words/Copy").add_theme_font_size_override("font_size", 11 if phone else 13 if tablet else 15)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome2").add_theme_constant_override("separation", 8 if phone or tablet else 16)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome2/Number").custom_minimum_size = Vector2(24 if phone else 30 if tablet else 44, 0)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome2/Number").add_theme_font_size_override("font_size", 27 if phone else 32 if tablet else 40)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome2/Words/Title").add_theme_font_size_override("font_size", 16 if phone else 19 if tablet else 22)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome2/Words/Copy").add_theme_font_size_override("font_size", 11 if phone else 13 if tablet else 15)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome3").add_theme_constant_override("separation", 8 if phone or tablet else 16)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome3/Number").custom_minimum_size = Vector2(24 if phone else 30 if tablet else 44, 0)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome3/Number").add_theme_font_size_override("font_size", 27 if phone else 32 if tablet else 40)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome3/Words/Title").add_theme_font_size_override("font_size", 16 if phone else 19 if tablet else 22)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome3/Words/Copy").add_theme_font_size_override("font_size", 11 if phone else 13 if tablet else 15)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome4").add_theme_constant_override("separation", 8 if phone or tablet else 16)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome4/Number").custom_minimum_size = Vector2(24 if phone else 30 if tablet else 44, 0)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome4/Number").add_theme_font_size_override("font_size", 27 if phone else 32 if tablet else 40)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome4/Words/Title").add_theme_font_size_override("font_size", 16 if phone else 19 if tablet else 22)
	get_node(^"Main/Frame/Inset/Content/Outcomes/Outcome4/Words/Copy").add_theme_font_size_override("font_size", 11 if phone else 13 if tablet else 15)
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Pips").add_theme_constant_override("separation", 6 if phone else 8 if tablet else 12)
	var side_Pip1 := 26 if phone else 40 if tablet else 52
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip1").custom_minimum_size = Vector2(side_Pip1, side_Pip1)
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip1/Number").add_theme_font_size_override("font_size", 15 if phone else 24)
	var side_Pip2 := 26 if phone else 40 if tablet else 52
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip2").custom_minimum_size = Vector2(side_Pip2, side_Pip2)
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip2/Number").add_theme_font_size_override("font_size", 15 if phone else 24)
	var side_Pip3 := 26 if phone else 40 if tablet else 52
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip3").custom_minimum_size = Vector2(side_Pip3, side_Pip3)
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip3/Number").add_theme_font_size_override("font_size", 15 if phone else 24)
	var side_Pip4 := 26 if phone else 40 if tablet else 52
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip4").custom_minimum_size = Vector2(side_Pip4, side_Pip4)
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Pips/Pip4/Number").add_theme_font_size_override("font_size", 15 if phone else 24)
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Rules/First").add_theme_constant_override("separation", 3 if phone else 8)
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Rules/First/Caption").add_theme_font_size_override("font_size", 11 if phone else 15)
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Rules/First/Value").add_theme_font_size_override("font_size", 12 if phone else 16 if tablet else 20)
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Rules/Last").add_theme_constant_override("separation", 3 if phone else 8)
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Rules/Last/Caption").add_theme_font_size_override("font_size", 11 if phone else 15)
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Rules/Last/Value").add_theme_font_size_override("font_size", 12 if phone else 16 if tablet else 20)
	for path in [^"Main/Frame/Inset/Content/Counter/Tracker/Controls/Undo", ^"Main/Frame/Inset/Content/Counter/Tracker/Controls/Next", ^"Main/Frame/Inset/Content/Footer/Broken", ^"Main/Frame/Inset/Content/Footer/Recover", ^"Main/Frame/Inset/Content/Footer/Treat", ^"Main/Frame/Inset/Content/Footer/UndoDeath", ^"Main/Frame/Inset/Content/Footer/EditHP"]:
		get_node(path).add_theme_font_size_override("font_size", 12 if phone else 14 if tablet else 16)
	get_node(^"Main/Frame/Inset/Content/Counter/Tracker/Rules").add_theme_constant_override("separation", 12 if phone else 16 if tablet else 24)
	get_node(^"Main/Frame/Inset/Content/Death").add_theme_constant_override("separation", 24 if phone else 40)
	get_node(^"Results/Inset/Values").add_theme_constant_override("separation", 12 if phone or tablet else 24)
	get_node(^"Results/Inset/Values/Broken").add_theme_constant_override("separation", 2 if phone else 4)
	get_node(^"Results/Inset/Values/Broken/Caption").add_theme_font_size_override("font_size", 10 if phone else 13)
	get_node(^"Results/Inset/Values/Broken/Value").add_theme_font_size_override("font_size", 11 if phone else 14 if tablet else 16)
	get_node(^"Results/Inset/Values/Injury").add_theme_constant_override("separation", 2 if phone else 4)
	get_node(^"Results/Inset/Values/Injury/Caption").add_theme_font_size_override("font_size", 10 if phone else 13)
	get_node(^"Results/Inset/Values/Injury/Value").add_theme_font_size_override("font_size", 11 if phone else 14 if tablet else 16)
	get_node(^"Results/Inset/Values/Duration").add_theme_constant_override("separation", 2 if phone else 4)
	get_node(^"Results/Inset/Values/Duration/Caption").add_theme_font_size_override("font_size", 10 if phone else 13)
	get_node(^"Results/Inset/Values/Duration/Value").add_theme_font_size_override("font_size", 11 if phone else 14 if tablet else 16)
	get_node(^"Results/Inset/Values/Recovery").add_theme_constant_override("separation", 2 if phone else 4)
	get_node(^"Results/Inset/Values/Recovery/Caption").add_theme_font_size_override("font_size", 10 if phone else 13)
	get_node(^"Results/Inset/Values/Recovery/Value").add_theme_font_size_override("font_size", 11 if phone else 14 if tablet else 16)
	get_node(^"Results/Inset/Values/Elapsed").add_theme_constant_override("separation", 2 if phone else 4)
	get_node(^"Results/Inset/Values/Elapsed/Caption").add_theme_font_size_override("font_size", 10 if phone else 13)
	get_node(^"Results/Inset/Values/Elapsed/Value").add_theme_font_size_override("font_size", 11 if phone else 14 if tablet else 16)
