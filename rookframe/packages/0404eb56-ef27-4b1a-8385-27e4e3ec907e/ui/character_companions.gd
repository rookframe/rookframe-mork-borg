extends VBoxContainer

const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
signal back_requested
signal actor_requested(actor: SDK.Actor)

func _ready() -> void:
	get_node(^"Back").pressed.connect(_back)

func configure(actors: Array[SDK.Actor], descriptions: Array = []) -> void:
	get_node(^"Empty").visible = actors.is_empty() and descriptions.is_empty()
	for actor in actors:
		var row := Button.new()
		var data: Dictionary = actor.data
		row.text = "%s · %s / %s HP — Open sheet" % [str(data.get("name", "Creature")), str(data.get("hit_points", 0)), str(data.get("maximum_hit_points", 0))]
		row.custom_minimum_size = Vector2(0, 44)
		row.autowrap_mode = 2
		row.theme_type_variation = "RookframeSecondaryButton"
		row.pressed.connect(_open.bind(actor))
		get_node(^"Items").add_child(row)
	for raw_description in descriptions:
		var description: Dictionary = raw_description
		var label := Label.new()
		label.text = str(description.get("name", "Companion")) + "\n" + str(description.get("rules", ""))
		label.autowrap_mode = 2
		label.theme_type_variation = "RookframeBody"
		get_node(^"Items").add_child(label)

func _open(actor: SDK.Actor) -> void:
	actor_requested.emit(actor)

func _back() -> void:
	back_requested.emit()
