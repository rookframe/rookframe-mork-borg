extends VBoxContainer
signal back_requested
signal rest_selected(kind: String)
var _daily := false

func _ready() -> void:
	get_node(^"Header/Back").pressed.connect(_back)
	get_node(^"Body/Main/Sections/Recovery").pressed.connect(_section.bind(false))
	get_node(^"Body/Main/Sections/Daily").pressed.connect(_section.bind(true))
	get_node(^"Body/Main/RestContent/Choices/Inset/Content/Breath").pressed.connect(_breath)
	get_node(^"Body/Main/RestContent/Choices/Inset/Content/Sleep").pressed.connect(_sleep)

func _back() -> void:
	back_requested.emit()

func _breath() -> void:
	rest_selected.emit("breath")

func _sleep() -> void:
	rest_selected.emit("sleep")

func _section(daily: bool) -> void:
	_daily = daily
	get_node(^"Body/Main/RestContent").visible = not daily
	get_node(^"Body/Main/DailyContent").visible = daily
	get_node(^"Body/Main/Sections/Recovery").set_pressed_no_signal(not daily)
	get_node(^"Body/Main/Sections/Daily").set_pressed_no_signal(daily)

func configure(data: Dictionary, kind: String, rest: String, action: Dictionary, texture: Texture2D) -> void:
	var phone := get_viewport_rect().size.y <= 560
	var tablet := get_viewport_rect().size.x <= 1150 and not phone
	add_theme_constant_override("separation", 8 if phone else 16 if tablet else 24)
	get_node(^"Header").custom_minimum_size = Vector2(0, 44 if phone else 70 if tablet else 80)
	get_node(^"Header/Titles/Identity").text = str(data.get("name", "Character")) + " · MÖRK BORG"
	get_node(^"Header/Titles/Title").text = "Rest" if kind == "rest" else "Getting better — or worse"
	get_node(^"Header/Titles/Title").add_theme_font_size_override("font_size", 20 if phone else 26 if tablet else 30)
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
	var step := 0 if phase in ["", "more_hp", "hp_gain"] else 1 if phase in ["debris", "silver", "scroll"] else 2 if phase.begins_with("ability") else 3
	for index in range(4):
		var path: NodePath = [^"Body/Main/Progress/HP", ^"Body/Main/Progress/Debris", ^"Body/Main/Progress/Abilities", ^"Body/Main/Progress/Class"][index]
		get_node(path).add_theme_color_override("font_color", Color(0.941176, 0.733333, 0.196078, 1) if index == step else Color(0.568627, 0.6, 0.603922, 1))
		get_node(path).add_theme_font_size_override("font_size", 11 if phone else 14 if tablet else 16)
	get_node(^"Body/Main/RestContent/Choices/Inset/Content/Breath").set_pressed_no_signal(rest == "breath")
	get_node(^"Body/Main/RestContent/Choices/Inset/Content/Sleep").set_pressed_no_signal(rest == "sleep")
	get_node(^"Body/Main/RestContent/Recovery/Inset/Content/HP").text = "%d / %d HP" % [int(data.get("hit_points", 0)), int(data.get("maximum_hit_points", 1))]
	get_node(^"Body/Main/RestContent/Recovery/Inset/Content/Result").text = str(action.get("message", "")) if str(action.get("state", "")) in ["resolved", "ended", "error"] else "Recover d%d HP, up to %d." % [4 if rest == "breath" else 6, int(data.get("maximum_hit_points", 1))]
	get_node(^"Body/Main/DailyContent/Power/Inset/Content/Value").text = "%d / %d" % [int(data.get("power_uses", 0)), int(data.get("power_uses_total", 0))]
	get_node(^"Body/Main/DailyContent/Omens/Inset/Content/Value").text = str(data.get("omens", 0))
	get_node(^"Footer/Status").text = "Power uses and Omens remain unchanged. Resolve food, drink and infection at the table." if kind == "rest" else "Accepted changes remain if this procedure ends."
	get_node(^"Footer/Status").add_theme_font_size_override("font_size", 11 if phone else 14)
	for path in [^"Body/Main/RestContent/Choices/Inset", ^"Body/Main/RestContent/Recovery/Inset", ^"Body/Main/DailyContent/Power/Inset", ^"Body/Main/DailyContent/Omens/Inset", ^"Body/Main/Procedure/Inset"]:
		for edge in ["left", "right", "top", "bottom"]:
			get_node(path).add_theme_constant_override("margin_" + edge, 8 if phone else 16 if tablet else 24)
	for path in [^"Body/Main/RestContent/Choices/Inset/Content/Heading", ^"Body/Main/RestContent/Recovery/Inset/Content/Heading", ^"Body/Main/DailyContent/Power/Inset/Content/Heading", ^"Body/Main/DailyContent/Omens/Inset/Content/Heading"]:
		get_node(path).add_theme_font_size_override("font_size", 12 if phone else 16)
	for path in [^"Body/Main/RestContent/Choices/Inset/Content/Breath", ^"Body/Main/RestContent/Choices/Inset/Content/Sleep"]:
		get_node(path).custom_minimum_size = Vector2(44, 58 if phone else 88 if tablet else 92)
		get_node(path).add_theme_font_size_override("font_size", 12 if phone else 15)
	get_node(^"Body/Main/RestContent/Recovery/Inset/Content/HP").add_theme_font_size_override("font_size", 28 if phone else 42)
	for path in [^"Body/Main/RestContent/Recovery/Inset/Content/Result", ^"Body/Main/DailyContent/Power/Inset/Content/Rules", ^"Body/Main/DailyContent/Omens/Inset/Content/Rules"]:
		get_node(path).add_theme_font_size_override("font_size", 12 if phone else 16)
