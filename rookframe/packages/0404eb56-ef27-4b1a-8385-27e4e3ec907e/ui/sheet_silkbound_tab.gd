extends Button

func _ready() -> void:
	get_node(^"Center/Content/Title").text = text
	get_node(^"Center/Content/Icon").texture = icon
	accessibility_name = text
	text = ""
	icon = null
	toggled.connect(_selected)
	_selected(button_pressed)

func configure_layout(font_size: int, icon_size: int, gap: int) -> void:
	get_node(^"Center/Content/Title").add_theme_font_size_override("font_size", font_size)
	get_node(^"Center/Content/Icon").custom_minimum_size = Vector2(icon_size, icon_size)
	get_node(^"Center/Content").add_theme_constant_override("separation", gap)

func set_selected(selected: bool) -> void:
	set_pressed_no_signal(selected)
	_selected(selected)

func _selected(selected: bool) -> void:
	get_node(^"Center/Content/Title").add_theme_color_override("font_color", Color(0.082353, 0.090196, 0.098039, 1) if selected else Color(0.682353, 0.729412, 0.745098, 1))
	get_node(^"Center/Content/Icon").self_modulate = Color(0.082353, 0.090196, 0.098039, 1) if selected else Color(0.815686, 0.745098, 0.556863, 1)
