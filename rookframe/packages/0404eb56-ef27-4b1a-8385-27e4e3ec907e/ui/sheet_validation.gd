extends VBoxContainer
## Routes validation to each authored inline copy of a shared field.
const FIELDS := {
	"silver": [^"Body/Chapter/QuickResources/QuickSilverEditField", ^"Body/Chapter/ChapterCaption/SilverEditField"],
	"omens": [^"Body/Chapter/QuickResources/QuickOmensEditField", ^"Body/Core/Likeness/Vitals/OmensEdit/OmensCurrentField"],
	"Toughness": [^"Body/Core/Abilities/ToughnessRow/ToughnessEditField"],
	"Presence": [^"Body/Core/Abilities/PresenceRow/PresenceEditField"],
	"Agility": [^"Body/Core/Abilities/AgilityRow/AgilityEditField"],
	"Strength": [^"Body/Core/Abilities/StrengthRow/StrengthEditField"],
	"power_uses": [^"Body/Core/Likeness/Vitals/PowerUsesEdit/PowerUsesCurrentField"],
	"maximum_hit_points": [^"Body/Core/Likeness/Vitals/HitPointsEdit/HitPointsMaximumField"],
	"hit_points": [^"Body/Core/Likeness/Vitals/HitPointsEdit/HitPointsCurrentField"],
	"name": [^"Header/NameEditField"],
}

func show_error(field: String, message: String) -> void:
	var paths: Array = FIELDS.get(field, [])
	for path in paths:
		get_node(path).show_error(message)

func clear_errors() -> void:
	for field in FIELDS.keys():
		show_error(str(field), "")
