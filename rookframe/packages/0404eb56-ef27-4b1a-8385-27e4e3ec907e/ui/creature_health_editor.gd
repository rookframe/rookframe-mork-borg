extends VBoxContainer
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const HEALTH = preload(ROOT + "logic/creature_health.gd")
const I18N = preload(ROOT + "ui/localization.gd")
signal adjustment_requested(operation: String, amount: String)
signal correction_requested
var _locale := I18N.new()

func _ready() -> void:
	get_node("Actions/Damage").pressed.connect(_adjust.bind("damage"))
	get_node("Actions/Heal").pressed.connect(_adjust.bind("heal"))
	get_node("Correct").pressed.connect(_correct)

func configure(locale: I18N, phone: bool) -> void:
	_locale = locale
	get_node("Amount").configure("amount", locale.text("Amount"), "1")
	get_node("Amount").configure_layout(phone)
	get_node("Actions/Damage").text = locale.text("Apply damage")
	get_node("Actions/Heal").text = locale.text("Heal")
	get_node("Correct").text = locale.text("Edit sheet")
	get_node("Summary").add_theme_font_size_override("font_size", 13 if phone else 18)

func refresh(data: Dictionary, enabled: bool, pending: bool) -> void:
	var valid := HEALTH.new().valid(data)
	get_node("Summary").text = _locale.text("Current HP") + ": " + str(data.get("hit_points", "—")) + " / " + str(data.get("maximum_hit_points", "—")) if valid else _locale.text("HP is unavailable. Use Edit sheet to correct it.")
	get_node("Amount").visible = valid
	get_node("Amount/Value").editable = enabled and not pending
	get_node("Actions").visible = valid
	for action in ["Damage", "Heal"]:
		get_node("Actions/" + action).disabled = not enabled or pending
	get_node("Correct").visible = not valid
	get_node("Correct").disabled = not enabled or pending

func show_error(message: String, field: String) -> void:
	if field == "amount":
		get_node("Amount").show_error(_locale.text(message))

func _adjust(operation: String) -> void:
	adjustment_requested.emit(operation, get_node("Amount").current_value())

func _correct() -> void:
	correction_requested.emit()
