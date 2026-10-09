extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
## One System HUD contribution, with each Actor schema owning its authored view.
func ready() -> void:
	if sdk == null:
		visible = false
		return
	for scene in [preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_hud.tscn"), preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_hud.tscn")]:
		var view = scene.instantiate()
		view.sdk = sdk
		add_child(view)
		view.visibility_changed.connect(_sync_visibility)
	_sync_visibility()

func _sync_visibility() -> void:
	var shown := false
	for child in get_children():
		var control := child as Control
		if control != null and control.visible:
			shown = true
	visible = shown
