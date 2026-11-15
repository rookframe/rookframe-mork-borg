extends RefCounted
## The World theme a suite mounts Package surfaces under, standing in for the host.
##
## `tests/run_character_creation.py` runs every suite that uses this once per
## UI Kit theme and names the theme in ROOKFRAME_WORLD_THEME. Run alone, a
## suite uses Silkbound Ledger.

const NAMES: Array[String] = ["silkbound-ledger", "fantasy", "cyberpunk"]


static func name() -> String:
	var selected := OS.get_environment("ROOKFRAME_WORLD_THEME").strip_edges()
	if selected.is_empty():
		return NAMES[0]
	assert(selected in NAMES, "ROOKFRAME_WORLD_THEME must be one of %s." % ", ".join(NAMES))
	return selected


static func entry() -> Theme:
	return load("res://rookframe/ui/themes/%s/theme.tres" % name())
