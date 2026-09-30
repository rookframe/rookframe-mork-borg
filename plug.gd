extends "res://addons/gd-plug/plug.gd"


func request_quit(exit_code := -1) -> bool:
	return super.request_quit(0 if exit_code == -1 else exit_code)


func _plugging() -> void:
	# GdUnit4 v6.2.1: development dependency, excluded from exported Packages.
	plug("godot-gdunit-labs/gdUnit4", {"commit": "08ffc7c65b61b1b2edd545616061a99973c13ce1", "include": ["addons/gdUnit4"]})
	plug("rookframe/rookframe-sdk", {"tag": "v0.32.7", "include": ["addons/rookframe_sdk"]})
	plug("rookframe/rookframe-ui-kit", {"commit": "80118d6d5b4225697d6646208c89995b3e31c46d", "include": ["rookframe/ui"]})
