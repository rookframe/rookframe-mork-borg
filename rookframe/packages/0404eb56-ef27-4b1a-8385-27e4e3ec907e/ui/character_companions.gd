extends VBoxContainer

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()

const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/companion_row.tscn")
const DIVIDER = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/inventory_divider.tscn")
signal placement_requested(actor: SDK.Actor)
signal back_requested
signal actor_requested(actor: SDK.Actor)

func _ready() -> void:
	get_node(^"BackRow/Back").pressed.connect(_back)

func configure(actors: Array[SDK.Actor], descriptions: Array = []) -> void:
	get_node(^"Section/Content/Empty").visible = actors.is_empty() and descriptions.is_empty()
	for actor in actors:
		var row := ROW.instantiate()
		i18n.companion_row(row)
		var data: Dictionary = actor.data
		var title := row.get_node(^"Info/Name") as Label
		title.text = str(data.get("name", "Creature"))
		var details := row.get_node(^"Info/Details") as Label
		details.text = _t("%s / %s HP · %s") % [str(data.get("hit_points", 0)), str(data.get("maximum_hit_points", 0)), _t(str(data.get("grant_source", "Starting companion")))]
		var open := row.get_node(^"Actions/Open") as Button
		open.pressed.connect(_open.bind(actor))
		var place := row.get_node(^"Actions/Place") as Button
		place.disabled = actor.access_level != "Owner"
		place.pressed.connect(_place.bind(actor))
		_append_record(row)
	for raw_description in descriptions:
		var description: Dictionary = raw_description
		var label := Label.new()
		label.text = _t(str(description.get("name", "Companion"))) + "\n" + _t(str(description.get("rules", "")))
		label.autowrap_mode = 2
		label.theme_type_variation = "RookframeBody"
		_append_record(label)

func _open(actor: SDK.Actor) -> void:
	actor_requested.emit(actor)

func _back() -> void:
	back_requested.emit()

func _place(actor: SDK.Actor) -> void:
	placement_requested.emit(actor)

func _append_record(record: Control) -> void:
	var items := get_node(^"Section/Content/Items")
	if items.get_child_count() > 0:
		items.add_child(DIVIDER.instantiate())
	items.add_child(record)


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"BackRow/Back").accessibility_name = _t("Back to Character")
	get_node(^"BackRow/Back").text = _t("Back")
	get_node(^"BackRow/Back").tooltip_text = _t("Back to Character")
	get_node(^"BackRow/Label").text = _t("Companions")
	get_node(^"Section/Content/Empty").text = _t("No granted Creature sheets are available to you.")
	get_node(^"Section/Content/Hint").text = _t("Each creature has its own sheet. Place its Rook after creation.")
	get_node(^"Section/Content/Title").text = _t("GRANTED CREATURES")
