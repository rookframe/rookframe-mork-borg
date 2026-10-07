extends VBoxContainer
@onready var _status: Label = get_node(^"Status")
## Routes draft text and validation to each authored inline copy of a shared field.
## Retain native references before phone footers reparent the quick controls.
@onready var _fields: Dictionary = {
	"silver": [get_node(^"Body/Chapter/Page/Content/QuickResources/QuickSilverEditField"), get_node(^"Body/Chapter/Page/Content/ChapterCaption/SilverEditField"), get_node(^"Body/Chapter/Page/Content/Collections/Secondary/Content/ResourceEditors/Pages/Area/Rows/Silver/Row/Editors/silver")],
	"omens": [get_node(^"Body/Chapter/Page/Content/QuickResources/QuickOmensEditField"), get_node(^"Body/Core/Likeness/Vitals/OmensEdit/OmensCurrentField"), get_node(^"Body/Chapter/Page/Content/Collections/Secondary/Content/ResourceEditors/Pages/Area/Rows/Omens/Row/Editors/omens")],
	"Toughness": [get_node(^"Body/Core/Abilities/ToughnessRow/ToughnessEditField")],
	"Presence": [get_node(^"Body/Core/Abilities/PresenceRow/PresenceEditField")],
	"Agility": [get_node(^"Body/Core/Abilities/AgilityRow/AgilityEditField")],
	"Strength": [get_node(^"Body/Core/Abilities/StrengthRow/StrengthEditField")],
	"power_uses": [get_node(^"Body/Core/Likeness/Vitals/PowerUsesEdit/PowerUsesCurrentField"), get_node(^"Body/Chapter/Page/Content/Collections/Secondary/Content/ResourceEditors/Pages/Area/Rows/Powers/Row/Editors/power_uses"), get_node(^"Body/Chapter/Page/Content/ChapterCaption/PowerEditField")],
	"maximum_hit_points": [get_node(^"Body/Core/Likeness/Vitals/HitPointsEdit/HitPointsMaximumField"), get_node(^"Body/Chapter/Page/Content/Collections/Secondary/Content/ResourceEditors/Pages/Area/Rows/HP/Row/Editors/maximum_hit_points")],
	"hit_points": [get_node(^"Body/Core/Likeness/Vitals/HitPointsEdit/HitPointsCurrentField"), get_node(^"Body/Chapter/Page/Content/Collections/Secondary/Content/ResourceEditors/Pages/Area/Rows/HP/Row/Editors/hit_points")],
	"name": [get_node(^"Header/NameEditField")],
}

func sync_draft_field(field: String, text: String) -> void:
	var controls: Array = _fields.get(field, [])
	for control in controls:
		var editor := control.get_node(^"Editor") as LineEdit
		# The source already has this text; leave its caret and selection intact.
		if editor.text != text:
			editor.text = text

func show_error(field: String, message: String) -> void:
	var controls: Array = _fields.get(field, [])
	for control in controls:
		control.show_error(message)

func clear_errors() -> void:
	for field in _fields.keys():
		show_error(str(field), "")

func place_status(in_chapter: bool) -> void:
	var destination: Node = get_node(^"Body/Chapter") if in_chapter else self
	if _status.get_parent() != destination:
		_status.get_parent().remove_child(_status)
		destination.add_child(_status)

func show_status(message: String) -> void:
	_status.text = message
	_status.visible = not message.is_empty()
	_status.tooltip_text = message
	_status.accessibility_description = message

func configure_density(phone: bool, tablet: bool) -> void:
	add_theme_constant_override("separation", 8 if phone else 16)
	get_node(^"Body").add_theme_constant_override("separation", 26 if phone else 24 if tablet else 44)
	get_node(^"Header").configure_layout(phone, tablet)
