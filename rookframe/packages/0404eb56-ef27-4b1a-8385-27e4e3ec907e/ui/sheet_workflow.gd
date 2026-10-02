extends VBoxContainer
signal back_requested
signal rest_selected(kind: String)
signal section_changed
var _daily := false

func _ready() -> void:
	get_node(^"Header/Back").pressed.connect(_back)
	get_node(^"Body/Main/Sections/Recovery").pressed.connect(_section.bind(false))
	get_node(^"Body/Main/Sections/Daily").pressed.connect(_section.bind(true))
	get_node(^"Body/Main/RestContent/Choices/Inset/Content/Breath").pressed.connect(_breath)
	get_node(^"Body/Main/RestContent/Choices/Inset/Content/Sleep").pressed.connect(_sleep)

func begin() -> void:
	_section(false)

func is_daily() -> bool:
	return _daily

func focus_back() -> void:
	get_node(^"Header/Back").grab_focus()

func _back() -> void:
	back_requested.emit()

func _breath() -> void:
	rest_selected.emit("breath")

func _sleep() -> void:
	rest_selected.emit("sleep")

func _section(daily: bool) -> void:
	_daily = daily
	section_changed.emit()
	get_node(^"Body/Main/RestContent").visible = not daily
	get_node(^"Body/Main/DailyContent").visible = daily
	get_node(^"Body/Main/Sections/Recovery").set_pressed_no_signal(not daily)
	get_node(^"Body/Main/Sections/Daily").set_pressed_no_signal(daily)

func configure(data: Dictionary, kind: String, rest: String, action: Dictionary, texture: Texture2D) -> void:
	var phone := get_viewport_rect().size.y <= 560
	var tablet := get_viewport_rect().size.x <= 1150 and not phone
	add_theme_constant_override("separation", 6 if phone else 20 if tablet else 24)
	get_node(^"Header").custom_minimum_size = Vector2(0, 54 if phone else 70 if tablet else 80)
	get_node(^"Header/Titles/Identity").text = str(data.get("name", "Character")) + " · MÖRK BORG"
	get_node(^"Header/Titles/Title").text = "Rest" if kind == "rest" else "Getting better — or worse"
	get_node(^"Header/Titles/Title").add_theme_font_size_override("font_size", 23 if phone else 26 if tablet else 30)
	get_node(^"Footer").custom_minimum_size = Vector2(0, 50 if phone else 66 if tablet else 70)
	get_node(^"Body/Main").add_theme_constant_override("separation", 6 if phone else 16)
	get_node(^"Header/HP").text = "HP %d / %d" % [int(data.get("hit_points", 0)), int(data.get("maximum_hit_points", 1))]
	get_node(^"Body").add_theme_constant_override("separation", 24 if tablet else 44)
	get_node(^"Body/Context").visible = not phone
	get_node(^"Body/Context").custom_minimum_size = Vector2(170 if tablet else 250, 0)
	get_node(^"Body/Context/Portrait").custom_minimum_size = Vector2(170, 212) if tablet else Vector2(250, 312)
	get_node(^"Body/Context/Portrait").texture = texture
	get_node(^"Body/Context/Name").text = str(data.get("name", "Character"))
	get_node(^"Body/Context/Class").text = str(data.get("class_title", "Character"))
	get_node(^"Body/Context/HP").text = "Hit points
%d / %d" % [int(data.get("hit_points", 0)), int(data.get("maximum_hit_points", 1))]
	var abilities: Dictionary = data.get("abilities", {})
	var copy := ""
	for key in ["Strength", "Agility", "Presence", "Toughness"]:
		var entry: Dictionary = abilities.get(str(key), {})
		copy += "%s  %+d
" % [key, int(entry.get("modifier", 0))]
	get_node(^"Body/Context/Abilities").text = copy
	get_node(^"Body/Main/Sections").visible = kind == "rest"
	get_node(^"Body/Main/Progress").visible = kind == "improve"
	get_node(^"Body/Main/Procedure").visible = kind == "improve"
	get_node(^"Body/Main/RestContent").visible = kind == "rest" and not _daily
	get_node(^"Body/Main/DailyContent").visible = kind == "rest" and _daily
	get_node(^"Body/Main/Sections/Recovery").set_pressed_no_signal(not _daily)
	get_node(^"Body/Main/Sections/Daily").set_pressed_no_signal(_daily)
	var phase := str(action.get("phase", ""))
	var step := 0 if phase in ["", "more_hp", "hp_increase"] else 1 if phase in ["debris", "silver", "scroll"] else 2 if phase == "abilities" else 3
	var resolved := str(action.get("state", "")) == "resolved"
	var labels := ["Hit points", "Debris", "Abilities", "Class"]
	get_node(^"Body/Main/Progress/Summary").text = "Improvement complete · 4 / 4" if resolved else "Step %d / 4 · %s" % [step + 1, labels[step]]
	get_node(^"Body/Main/Progress").accessibility_description = get_node(^"Body/Main/Progress/Summary").text
	for index in range(4):
		var title_path: NodePath = [^"Body/Main/Progress/Steps/HP/Title", ^"Body/Main/Progress/Steps/Debris/Title", ^"Body/Main/Progress/Steps/Abilities/Title", ^"Body/Main/Progress/Steps/Class/Title"][index]
		var current_path: NodePath = [^"Body/Main/Progress/Steps/HP/Current", ^"Body/Main/Progress/Steps/Debris/Current", ^"Body/Main/Progress/Steps/Abilities/Current", ^"Body/Main/Progress/Steps/Class/Current"][index]
		var path: NodePath = [^"Body/Main/Progress/Steps/HP", ^"Body/Main/Progress/Steps/Debris", ^"Body/Main/Progress/Steps/Abilities", ^"Body/Main/Progress/Steps/Class"][index]
		var complete := index < step or resolved
		get_node(title_path).text = ("✓ " if complete else "%02d · " % (index + 1)) + str(labels[index])
		get_node(title_path).add_theme_color_override("font_color", Color(0.941176, 0.733333, 0.196078, 1) if index == step and not resolved else Color(0.568627, 0.6, 0.603922, 1))
		get_node(title_path).add_theme_font_size_override("font_size", 11 if phone else 14 if tablet else 16)
		get_node(current_path).color = Color(0.941176, 0.733333, 0.196078, 1) if index == step and not resolved else Color(0.27451, 0.321569, 0.337255, 1)
		get_node(path).accessibility_description = str(labels[index]) + (" · complete" if complete else " · current step" if index == step else " · upcoming")
	get_node(^"Body/Main/RestContent/Choices/Inset/Content/Breath").set_pressed_no_signal(rest == "breath")
	get_node(^"Body/Main/RestContent/Choices/Inset/Content/Sleep").set_pressed_no_signal(rest == "sleep")
	get_node(^"Body/Main/RestContent/Recovery/Inset/Scroll/Content/HP").text = "%d / %d HP" % [int(data.get("hit_points", 0)), int(data.get("maximum_hit_points", 1))]
	get_node(^"Body/Main/RestContent/Recovery/Inset/Scroll/Content/Result").text = str(action.get("message", "")) if str(action.get("state", "")) in ["resolved", "ended", "error"] else "Recover d%d HP, up to %d." % [4 if rest == "breath" else 6, int(data.get("maximum_hit_points", 1))]
	get_node(^"Body/Main/DailyContent/Power/Inset/Content/Value").text = "%d / %d" % [int(data.get("power_uses", 0)), int(data.power_uses_total)] if data.has("power_uses_total") else str(data.get("power_uses", 0))
	get_node(^"Body/Main/DailyContent/Omens/Inset/Content/Value").text = str(data.get("omens", 0))
	get_node(^"Footer/Status").text = "Power uses and Omens remain unchanged. Resolve food, drink and infection at the table." if kind == "rest" else "Accepted changes remain if this procedure ends."
	get_node(^"Footer/Status").add_theme_font_size_override("font_size", 11 if phone else 14)
	for path in [^"Body/Main/RestContent/Choices/Inset", ^"Body/Main/RestContent/Recovery/Inset", ^"Body/Main/DailyContent/Power/Inset", ^"Body/Main/DailyContent/Omens/Inset", ^"Body/Main/Procedure/Inset"]:
		for edge in ["left", "right", "top", "bottom"]:
			get_node(path).add_theme_constant_override("margin_" + edge, 8 if phone else 16 if tablet else 24)
	for path in [^"Body/Main/RestContent/Choices/Inset/Content/Heading", ^"Body/Main/RestContent/Recovery/Inset/Scroll/Content/Heading", ^"Body/Main/DailyContent/Power/Inset/Content/Heading", ^"Body/Main/DailyContent/Omens/Inset/Content/Heading"]:
		get_node(path).add_theme_font_size_override("font_size", 12 if phone else 16)
	for path in [^"Body/Main/RestContent/Choices/Inset/Content/Breath", ^"Body/Main/RestContent/Choices/Inset/Content/Sleep"]:
		get_node(path).disabled = not action.is_empty()
		get_node(path).custom_minimum_size = Vector2(44, 72 if phone else 88 if tablet else 92)
		get_node(path).add_theme_font_size_override("font_size", 12 if phone else 15)
	get_node(^"Body/Main/RestContent/Recovery/Inset/Scroll/Content/HP").add_theme_font_size_override("font_size", 28 if phone else 42)
	for path in [^"Body/Main/RestContent/Recovery/Inset/Scroll/Content/Result", ^"Body/Main/DailyContent/Power/Inset/Content/Rules", ^"Body/Main/DailyContent/Omens/Inset/Content/Rules"]:
		get_node(path).add_theme_font_size_override("font_size", 12 if phone else 16)

	get_node(^"Body/Main/RestContent/Recovery/Inset/Scroll/Content/Restrictions").add_theme_font_size_override("font_size", 12 if phone else 15)
	for path in [^"Body/Main/RestContent/Choices/Inset/Content", ^"Body/Main/RestContent/Recovery/Inset/Scroll/Content"]:
		get_node(path).add_theme_constant_override("separation", 8 if phone else 12)
