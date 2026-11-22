extends RefCounted
## Presents one Favorite entry on a UI Kit FavoriteToggle. The owner keeps the
## returned key and reports the star's pressed state with it.

static func configure(star: Button, entry: Dictionary, owner: bool, busy: bool = false) -> String:
	star.visible = not entry.is_empty()
	if entry.is_empty():
		return ""
	var starred: bool = entry.get("starred", false)
	star.set_pressed_no_signal(starred)
	star.accessibility_name = ("Unstar" if starred else "Star") + " · " + str(entry.get("name", "Entry"))
	star.tooltip_text = star.accessibility_name
	star.disabled = not owner or busy
	return str(entry.key)
