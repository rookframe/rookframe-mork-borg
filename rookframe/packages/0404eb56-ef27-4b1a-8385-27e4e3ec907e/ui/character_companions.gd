extends VBoxContainer

const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/companion_row.tscn")
signal placement_requested(actor: SDK.Actor)
signal back_requested
signal actor_requested(actor: SDK.Actor)

func _ready() -> void:
	get_node(^"Back").pressed.connect(_back)

func configure(actors: Array[SDK.Actor], descriptions: Array = []) -> void:
	get_node(^"Empty").visible = actors.is_empty() and descriptions.is_empty()
	for actor in actors:
		var row := ROW.instantiate()
		var data: Dictionary = actor.data
		var title := row.get_node(^"Name") as Label
		title.text = str(data.get("name", "Creature"))
		var details := row.get_node(^"Details") as Label
		details.text = "%s / %s HP · %s" % [str(data.get("hit_points", 0)), str(data.get("maximum_hit_points", 0)), str(data.get("grant_source", "Starting companion"))]
		var open := row.get_node(^"Actions/Open") as Button
		open.pressed.connect(_open.bind(actor))
		var place := row.get_node(^"Actions/Place") as Button
		place.disabled = actor.access_level != "Owner"
		place.pressed.connect(_place.bind(actor))
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

func _place(actor: SDK.Actor) -> void:
	placement_requested.emit(actor)
