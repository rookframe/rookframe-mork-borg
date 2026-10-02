extends PanelContainer
signal event_requested(operation: String)
signal broken_requested
const PATHS := {
	"NextRound": ^"Inset/Content/ConditionActions/NextRound", "UndoRound": ^"Inset/Content/ConditionActions/UndoRound",
	"Recover": ^"Inset/Content/ConditionActions/Recover", "AdvanceHour": ^"Inset/Content/ConditionActions/AdvanceHour",
	"UndoHour": ^"Inset/Content/ConditionActions/UndoHour", "Treat": ^"Inset/Content/ConditionActions/Treat",
}
func _ready() -> void:
	get_node(^"Inset/Content/ConditionActions/Broken").pressed.connect(_broken)
	for pair in [["NextRound", "next"], ["UndoRound", "undo"], ["Recover", "recover"], ["AdvanceHour", "next"], ["UndoHour", "undo"], ["Treat", "treat"]]:
		get_node(PATHS.get(str(pair[0]), ^"Inset/Content/ConditionActions/NextRound")).pressed.connect(_event.bind(str(pair[1])))

func _broken() -> void:
	broken_requested.emit()

func _event(operation: String) -> void:
	event_requested.emit(operation)

func configure(data: Dictionary, condition: Dictionary, enabled: bool, phone: bool) -> void:
	var tablet := get_viewport_rect().size.x <= 1150 and not phone
	for edge in ["left", "right", "top", "bottom"]:
		get_node(^"Inset").add_theme_constant_override("margin_" + edge, 10 if phone else 16 if tablet else 24)
	get_node(^"Inset/Content").add_theme_constant_override("separation", 6 if phone else 12)
	get_node(^"Inset/Content/ConditionTitle").text = str(condition.get("title", ""))
	get_node(^"Inset/Content/ConditionTitle").add_theme_font_size_override("font_size", 25 if phone else 32 if tablet else 48)
	get_node(^"Inset/Content/ConditionCopy").text = str(condition.get("copy", ""))
	get_node(^"Inset/Content/ConditionCopy").add_theme_font_size_override("font_size", 12 if phone else 16 if tablet else 18)
	var incident: Dictionary = data.get("broken_incident", {})
	var outcome := int(incident.get("outcome", 0))
	var elapsed := int(incident.get("elapsed", 0))
	var duration := int(incident.get("duration", 0))
	var complete := incident.has("followup_sequence")
	var rounds: bool = complete and outcome in [1, 2] and not incident.get("recovered", false) and not incident.get("dead", false)
	var hemorrhage: bool = complete and outcome == 3 and not incident.get("treated", false) and not incident.get("negative_hp", false)
	var active_counter: bool = rounds or hemorrhage and not incident.get("dead", false)
	get_node(^"Inset/Content/Metrics").visible = active_counter
	get_node(^"Inset/Content/Metrics/Remaining").text = "%d %s left" % [maxi(0, duration - elapsed), "rounds" if rounds else "hours"]
	get_node(^"Inset/Content/Metrics/Remaining").add_theme_font_size_override("font_size", 36 if phone else 54 if tablet else 72)
	get_node(^"Inset/Content/Metrics/Future").text = "Future recovery
%d HP" % int(incident.get("recovery_hp", 0)) if rounds else "DR16 first hour
DR18 last hour"
	get_node(^"Inset/Content/Metrics/Future").add_theme_font_size_override("font_size", 12 if phone else 16)
	get_node(^"Inset/Content/Rolls").visible = complete
	get_node(^"Inset/Content/Rolls").text = "Broken d4: %d" % outcome + (" · Injury d6: %d" % int(incident.get("injury_roll", 0)) if outcome == 2 else "") + (" · Duration d4: %d · Recovery d4: %d HP" % [duration, int(incident.get("recovery_hp", 0))] if outcome in [1, 2] else " · Deadline d2: %d hours" % duration if outcome == 3 else "")
	get_node(^"Inset/Content/Rolls").add_theme_font_size_override("font_size", 11 if phone else 14)
	get_node(^"Inset/Content/DeathMark").visible = int(data.get("hit_points", 0)) < 0 or incident.get("dead", false)
	get_node(^"Inset/Content/DeathMark").custom_minimum_size = Vector2(0, 64 if phone else 90)
	get_node(^"Inset/Content/ConditionActions/Broken").visible = int(data.get("hit_points", 0)) == 0 and (outcome == 0 or outcome in [1, 2, 3] and not complete)
	get_node(^"Inset/Content/ConditionActions/Broken").text = "Roll Broken d4" if outcome == 0 else "Complete Broken dice"
	get_node(^"Inset/Content/ConditionActions/Broken").disabled = not enabled
	var states := {"NextRound": rounds and elapsed < duration, "UndoRound": rounds and elapsed > 0, "Recover": rounds and duration > 0 and elapsed >= duration, "AdvanceHour": hemorrhage and elapsed < duration, "UndoHour": hemorrhage and elapsed > 0, "Treat": hemorrhage and not incident.get("dead", false)}
	get_node(^"Inset/Content/ConditionActions/Recover").text = "Awaken" if outcome == 1 else "Recover"
	for key in PATHS.keys():
		var control = get_node(PATHS.get(str(key), ^"Inset/Content/ConditionActions/NextRound"))
		control.visible = states.get(str(key), false)
		control.disabled = not enabled
		control.add_theme_font_size_override("font_size", 12 if phone else 14)
	for child in get_node(^"Inset/Content/Pips").get_children():
		get_node(^"Inset/Content/Pips").remove_child(child)
		child.queue_free()
	if rounds or hemorrhage:
		for index in range(duration):
			var pip := Label.new()
			pip.text = "×" if index < elapsed else str(index + 1)
			pip.custom_minimum_size = Vector2(26 if phone else 40, 26 if phone else 40)
			pip.horizontal_alignment = 1
			pip.vertical_alignment = 1
			pip.add_theme_color_override("font_color", Color(0.568627, 0.6, 0.603922, 1) if index < elapsed else Color(0.937255, 0.356863, 0.329412, 1))
			get_node(^"Inset/Content/Pips").add_child(pip)
