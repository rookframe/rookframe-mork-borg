extends VBoxContainer
## Routes draft text and validation to each authored inline copy of a shared field.
## Retain native references before phone footers reparent the quick controls.
@onready var _fields: Dictionary = {
	"silver": [get_node(^"Body/Chapter/QuickResources/QuickSilverEditField"), get_node(^"Body/Chapter/ChapterCaption/SilverEditField"), get_node(^"Body/Chapter/Collections/Secondary/ResourceEditors/Pages/Area/Rows/Silver/Row/Editors/silver")],
	"omens": [get_node(^"Body/Chapter/QuickResources/QuickOmensEditField"), get_node(^"Body/Core/Likeness/Vitals/OmensEdit/OmensCurrentField"), get_node(^"Body/Chapter/Collections/Secondary/ResourceEditors/Pages/Area/Rows/Omens/Row/Editors/omens")],
	"Toughness": [get_node(^"Body/Core/Abilities/ToughnessRow/ToughnessEditField")],
	"Presence": [get_node(^"Body/Core/Abilities/PresenceRow/PresenceEditField")],
	"Agility": [get_node(^"Body/Core/Abilities/AgilityRow/AgilityEditField")],
	"Strength": [get_node(^"Body/Core/Abilities/StrengthRow/StrengthEditField")],
	"power_uses": [get_node(^"Body/Core/Likeness/Vitals/PowerUsesEdit/PowerUsesCurrentField"), get_node(^"Body/Chapter/Collections/Secondary/ResourceEditors/Pages/Area/Rows/Powers/Row/Editors/power_uses"), get_node(^"Body/Chapter/ChapterCaption/PowerEditField")],
	"maximum_hit_points": [get_node(^"Body/Core/Likeness/Vitals/HitPointsEdit/HitPointsMaximumField"), get_node(^"Body/Chapter/Collections/Secondary/ResourceEditors/Pages/Area/Rows/HP/Row/Editors/maximum_hit_points")],
	"hit_points": [get_node(^"Body/Core/Likeness/Vitals/HitPointsEdit/HitPointsCurrentField"), get_node(^"Body/Chapter/Collections/Secondary/ResourceEditors/Pages/Area/Rows/HP/Row/Editors/hit_points")],
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
