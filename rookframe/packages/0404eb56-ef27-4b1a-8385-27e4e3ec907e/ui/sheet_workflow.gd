extends VBoxContainer
signal back_requested
signal rest_selected(kind: String)
signal section_changed
var _daily := false
var prepared := false
const MAIN := ^"Body/Main/Content"
const CHOICES := ^"Body/Main/Content/RestContent/Choices/Frame/Inset/Pages/Area/Content"
const RECOVERY := ^"Body/Main/Content/RestContent/Recovery/Frame/Inset/Pages/Area/Content"
const DAILY := ^"Body/Main/Content/DailyContent/Frame/Inset/Pages/Area/Content"
const CONTEXT := ^"Body/Context/Inset/Content"

func _ready() -> void:
	get_node(^"Header/Back").pressed.connect(_back)
	get_node(MAIN).get_node(^"Sections/Recovery").pressed.connect(_section.bind(false))
	get_node(MAIN).get_node(^"Sections/Daily").pressed.connect(_section.bind(true))
	get_node(CHOICES).get_node(^"Breath").pressed.connect(_select_rest.bind("breath"))
	get_node(CHOICES).get_node(^"Sleep").pressed.connect(_select_rest.bind("sleep"))

func begin() -> void:
	prepared = false
	_section(false)

func is_daily() -> bool:
	return _daily

func focus_back() -> void:
	get_node(^"Header/Back").grab_focus()

func _back() -> void:
	back_requested.emit()

func _select_rest(kind: String) -> void:
	rest_selected.emit(kind)

func _section(daily: bool) -> void:
	_daily = daily
	section_changed.emit()

func configure(data: Dictionary, kind: String, rest: String, action: Dictionary, texture: Texture2D) -> void:
	var phone := get_viewport_rect().size.y <= 560
	var tablet := get_viewport_rect().size.x <= 1150 and not phone
	var main = get_node(MAIN)
	var context = get_node(CONTEXT)
	add_theme_constant_override("separation", 6 if phone else 20 if tablet else 28)
	get_node(^"Header").custom_minimum_size = Vector2(get_node(^"Header").custom_minimum_size.x, 54 if phone else 70 if tablet else 80)
	get_node(^"Header/Titles/Identity").text = str(data.get("name", "Character")) + " · MÖRK BORG"
	get_node(^"Header/Titles/Title").text = "Rest" if kind == "rest" else "Getting better — or worse"
	get_node(^"Header/Titles/Title").add_theme_font_size_override("font_size", 23 if phone else 26 if tablet else 30)
	get_node(^"Header/HP").text = "HP %d / %d" % [int(data.get("hit_points", 0)), int(data.get("maximum_hit_points", 1))]
	get_node(^"Footer").custom_minimum_size = Vector2(get_node(^"Footer").custom_minimum_size.x, 50 if phone else 66 if tablet else 70)
	get_node(^"Footer/Status").add_theme_font_size_override("font_size", 11 if phone else 14)
	get_node(^"Body").add_theme_constant_override("separation", 24 if tablet else 44)
	get_node(^"Body/Context").visible = not phone
	get_node(^"Body/Context").custom_minimum_size = Vector2(190 if tablet else 280, get_node(^"Body/Context").custom_minimum_size.y)
	get_node(^"Body/Context/Inset").add_theme_constant_override("margin_right", 20 if tablet else 28)
	context.add_theme_constant_override("separation", 10 if tablet else 14)
	context.get_node(^"Portrait").custom_minimum_size = Vector2(170, 212) if tablet else Vector2(250, 312)
	context.get_node(^"Portrait").texture = texture
	context.get_node(^"Name").text = str(data.get("name", "Character"))
	context.get_node(^"Name").max_lines_visible = 1
	context.get_node(^"Name").text_overrun_behavior = 3
	context.get_node(^"Name").add_theme_font_size_override("font_size", 25 if tablet else 28)
	context.get_node(^"Class").text = str(data.get("class_title", "Character"))
	context.get_node(^"HP/Value").text = str(data.get("hit_points", 0))
	context.get_node(^"HP/Maximum").text = "/ " + str(data.get("maximum_hit_points", 1))
	var abilities: Dictionary = data.get("abilities", {})
	for path in [^"Abilities/Strength/Value", ^"Abilities/Agility/Value", ^"Abilities/Presence/Value", ^"Abilities/Toughness/Value"]:
		var key := str(path).split("/")[1]
		context.get_node(path).text = "%+d" % int(abilities.get(key, {}).get("modifier", 0))
	context.get_node(^"Note").text = "Changes return to this character sheet." if kind == "rest" else "Improvement changes your maximum HP. It does not heal current wounds."
	context.get_node(^"Note").add_theme_font_size_override("font_size", 12 if tablet else 14)
	var side := int(maxf(0, (get_viewport_rect().size.x - 60 - 280 - 44 - 1300) / 2)) if not phone and not tablet else 0
	get_node(^"Body/Main").add_theme_constant_override("margin_left", side)
	get_node(^"Body/Main").add_theme_constant_override("margin_right", side)
	main.add_theme_constant_override("separation", 6 if phone else 16 if tablet else 24)
	main.get_node(^"Sections").visible = kind == "rest"
	main.get_node(^"Sections/Recovery").set_pressed_no_signal(not _daily)
	main.get_node(^"Sections/Daily").set_pressed_no_signal(_daily)
	main.get_node(^"RestContent").visible = kind == "rest" and not _daily
	main.get_node(^"DailyContent").visible = kind == "rest" and _daily
	main.get_node(^"Procedure").visible = kind == "improve"
	main.get_node(^"Progress").visible = kind == "improve" and not action.is_empty()
	main.get_node(^"RestContent").add_theme_constant_override("separation", 12 if phone else 16 if tablet else 28)
	for path in [^"RestContent/Choices", ^"RestContent/Recovery", ^"DailyContent"]:
		var panel = main.get_node(path)
		panel.get_node(^"Frame/Heading/Inset/Title").add_theme_font_size_override("font_size", 13 if phone else 16)

		for edge in ["left", "right", "top", "bottom"]:
			panel.get_node(^"Frame/Inset").add_theme_constant_override("margin_" + edge, 10 if phone else 16 if tablet else 24)
			panel.get_node(^"Frame/Heading/Inset").add_theme_constant_override("margin_" + edge, (10 if phone else 20) if edge in ["left", "right"] else 6 if phone else 12)
		panel.get_node(^"Frame/Inset/Pages/Area/Content").add_theme_constant_override("separation", 8 if phone else 14 if tablet else 20)
	for name in [^"Breath", ^"Sleep"]:
		var choice = get_node(CHOICES).get_node(name)
		choice.set_pressed_no_signal(rest == ("breath" if name == ^"Breath" else "sleep"))
		choice.disabled = not action.is_empty()
		choice.custom_minimum_size = Vector2(choice.custom_minimum_size.x, 72 if phone else 88 if tablet else 92)
		for edge in ["left", "right", "top", "bottom"]:
			choice.get_node(^"Inset").add_theme_constant_override("margin_" + edge, 10 if phone else 12 if tablet else 16)
		choice.get_node(^"Inset/Row/Icon").visible = not phone and not tablet
		choice.get_node(^"Inset/Row/Die").add_theme_font_size_override("font_size", 20 if phone else 21 if tablet else 24)
		choice.get_node(^"Inset/Row/Copy/Title").add_theme_font_size_override("font_size", 13 if phone else 16)
		choice.get_node(^"Inset/Row/Copy/Help").add_theme_font_size_override("font_size", 11 if phone else 13)
	var results: Dictionary = action.get("results", {})
	var result: Dictionary = results.get("rest", {})
	var recovery = get_node(RECOVERY)
	var strip = recovery.get_node(^"ResultFrame/Inset/Result")
	strip.get_node(^"Roll").text = "Recovery d%d · %d" % [4 if rest == "breath" else 6, int(result.get("roll", 0))] if not result.is_empty() else "Breath + drink" if rest == "breath" else "Full night's sleep"
	strip.get_node(^"HP/Value").text = "%d → %d" % [int(result.before), int(result.after)] if not result.is_empty() else str(data.get("hit_points", 0))
	strip.get_node(^"HP/Maximum").text = "/ %d HP" % int(data.get("maximum_hit_points", 1))
	strip.get_node(^"HP/Value").add_theme_font_size_override("font_size", 30 if phone else 42)
	strip.get_node(^"HP/Maximum").add_theme_font_size_override("font_size", 18 if phone else 22)
	strip.get_node(^"Copy").text = "Restored %d HP. Power uses and Omens are unchanged." % int(result.restored) if not result.is_empty() else str(action.get("message", "Recover d%d HP, up to your maximum." % [4 if rest == "breath" else 6]))
	for edge in ["left", "right", "top", "bottom"]:
		recovery.get_node(^"ResultFrame/Inset").add_theme_constant_override("margin_" + edge, (14 if phone else 24) if edge in ["left", "right"] else 10 if phone else 18)
	for path in [^"ResultFrame/Inset/Result/Copy", ^"Restrictions"]:
		recovery.get_node(path).add_theme_font_size_override("font_size", 12 if phone else 15)
	var daily = get_node(DAILY)
	for path in [^"Omens", ^"Power"]:
		daily.get_node(path).add_theme_constant_override("separation", 8 if phone else 16 if tablet else 20)
		daily.get_node(path).get_node(^"Term").custom_minimum_size = Vector2(116 if phone else 140 if tablet else 180, daily.get_node(path).get_node(^"Term").custom_minimum_size.y)
		daily.get_node(path).get_node(^"Term").add_theme_font_size_override("font_size", 12 if phone else 16)
		daily.get_node(path).get_node(^"Rules").add_theme_font_size_override("font_size", 12 if phone else 16)
	var profile: Dictionary = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creation_classes.gd").new().profile(str(data.get("class_id", "classless")))
	daily.get_node(^"Omens/Rules").text = "Only when depleted: after at least six hours’ rest, roll d%d at the table. Enter the resolved result with Edit sheet. Current Omens: %d." % [int(profile.get("omen_faces", 2)), int(data.get("omens", 0))]
	var uses := str(data.get("power_uses", 0))
	if data.has("power_uses_total"):
		uses += " / " + str(data.power_uses_total)
	daily.get_node(^"Power/Rules").text = "Each morning, roll Presence + d4 for the day’s uses. This is separate from sleep. Current uses: " + uses + "."
	get_node(^"Footer/Status").text = "Set elapsed time at the table; update resolved values in Edit sheet." if kind == "rest" and _daily else "Power uses and Omens remain unchanged." if kind == "rest" else "Accepted results remain if this procedure ends."
	var phase := str(action.get("phase", ""))
	var step := 0 if phase in ["", "more_hp", "hp_increase"] else 1 if phase in ["debris", "silver", "scroll"] else 2 if phase == "abilities" else 3
	var total := 4 if action.get("class_step", false) else 3
	var resolved := str(action.get("state", "")) == "resolved"
	var labels := ["More HP", "Debris", "Abilities", "Class"]
	main.get_node(^"Progress/Summary").text = "Improvement complete · %d / %d" % [total, total] if resolved else "Step %d / %d · %s" % [step + 1, total, labels[step]]
	main.get_node(^"Progress").accessibility_description = main.get_node(^"Progress/Summary").text
	var steps = [^"Progress/Steps/HP", ^"Progress/Steps/Debris", ^"Progress/Steps/Abilities", ^"Progress/Steps/Class"]
	for index in range(4):
		var entry = main.get_node(steps[index])
		entry.visible = index < total
		var completed := index < step or resolved
		entry.get_node(^"Title").text = ("✓ " if completed else "%d. " % [index + 1]) + str(labels[index])
		entry.get_node(^"Title").add_theme_font_size_override("font_size", 12 if phone else 14 if tablet else 16)
		entry.get_node(^"Title").add_theme_color_override("font_color", Color(0.941176, 0.733333, 0.196078, 1) if index == step and not resolved else Color(0.603922, 0.647059, 0.65098, 1))
		entry.get_node(^"Current").color = Color(0.941176, 0.733333, 0.196078, 1) if index == step and not resolved else Color(0.27451, 0.321569, 0.337255, 1)
		entry.accessibility_description = str(labels[index]) + (" · complete" if completed else " · current step" if index == step else " · upcoming")
