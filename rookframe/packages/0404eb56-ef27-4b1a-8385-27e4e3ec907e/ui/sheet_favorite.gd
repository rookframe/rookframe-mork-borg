extends Button
signal favorite_changed(key: String, starred: bool)
var _key := ""

func _ready() -> void:
	pressed.connect(_change)

func configure(entry: Dictionary, owner: bool, busy: bool = false) -> void:
	visible = not entry.is_empty()
	if entry.is_empty():
		return
	_key = str(entry.key)
	var starred: bool = entry.get("starred", false)
	set_pressed_no_signal(starred)
	text = "★" if starred else "☆"
	accessibility_name = ("Unstar" if starred else "Star") + " · " + str(entry.get("name", "Entry"))
	tooltip_text = accessibility_name
	disabled = not owner or busy

func _change() -> void:
	favorite_changed.emit(_key, button_pressed)
