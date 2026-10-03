extends "res://addons/gd-plug/plug.gd"


func request_quit(exit_code := -1) -> bool:
	return super.request_quit(0 if exit_code == -1 else exit_code)


func _plugging() -> void:
	# GdUnit4 v6.2.1: development dependency, excluded from exported Packages.
	plug("godot-gdunit-labs/gdUnit4", {"commit": "08ffc7c65b61b1b2edd545616061a99973c13ce1", "include": ["addons/gdUnit4"]})
	plug("rookframe/rookframe-sdk", {"tag": "v0.32.20", "include": ["addons/rookframe_sdk"]})
	plug("rookframe/rookframe-ui-kit", {"commit": "b8aa5fa929f0f352096d63a53f01bf1e0af39b70", "include": ["rookframe/ui"]})
