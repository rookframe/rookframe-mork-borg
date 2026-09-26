extends VBoxContainer

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()
signal appearance_save_requested(scope: String, index: int)
const CHOICE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/miniature_choice.tscn")
var _choices: Array[Dictionary] = []
var _selection: Dictionary = {}
var _default_rows: Array[Button] = []
var _selected_rows: Array[Button] = []
func _ready() -> void:
	for scope in ["Default", "Selected"]:
		get_node(scope + "/Content/Row/Details/Choose").pressed.connect(_choose.bind(scope))
		get_node(scope + "/Content/Row/Details/Apply").pressed.connect(_apply.bind(scope))
func configure(data: Dictionary, _count: int, choices: Array[Dictionary]) -> void:
	_choices = choices
	var read_only: bool = data.get("read_only", false)
	for scope in ["Default", "Selected"]:
		var reference: Dictionary = data.get("preferred_miniature" if scope == "Default" else "selected_miniature", {})
		var title := "No Miniature selected"
		var picker := get_node(scope + "/Content/Row/Details/Picker") as VBoxContainer
		_selection[scope] = 0
		for index in range(choices.size()):
			var choice: Dictionary = choices[index]
			var row = CHOICE.instantiate()
			i18n.miniature_choice(row)
			picker.add_child(row)
			if scope == "Default":
				_default_rows.append(row)
			else:
				_selected_rows.append(row)
			row.text = _t(str(choice.get("title", "Miniature")))
			row.pressed.connect(_select.bind(scope, index + 1))
			if str(reference.get("package_id", "")) == str(choice.get("package_id", "")) and str(reference.get("local_id", "")) == str(choice.get("local_id", "")):
				title = str(choice.get("title", "Miniature"))
				_selection[scope] = index + 1
				row.button_pressed = true
		var rook_available: bool = data.get("selected_rook_available", false)
		var available: bool = scope == "Default" or rook_available
		get_node(scope + "/Content/Row/Details/Title").text = _t(title) if available else _t("Select this Character’s Rook")
		get_node(scope + "/Content/Row/Details/Choose").disabled = choices.is_empty() or not available or read_only
func _choose(scope: String) -> void:
	get_node(scope + "/Content/Row/Details/Picker").visible = true
	get_node(scope + "/Content/Row/Details/Apply").visible = true
	get_node(scope + "/Content/Row/Details/Choose").visible = false
func _apply(scope: String) -> void:
	appearance_save_requested.emit(scope, int(_selection.get(scope, 0)))

func _select(scope: String, index: int) -> void:
	_selection[scope] = index
	var children: Array[Button] = _default_rows if scope == "Default" else _selected_rows
	for offset in range(children.size()):
		children[offset].button_pressed = offset + 1 == index


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"Default/Content/Heading").text = _t("ACTOR DEFAULT")
	get_node(^"Default/Content/Row/Details/Apply").text = _t("Use Miniature")
	get_node(^"Default/Content/Row/Details/Choose").text = _t("Choose Miniature")
	get_node(^"Default/Content/Row/Details/Description").text = _t("Preferred Miniature for this Actor’s Rooks.")
	get_node(^"Selected/Content/Heading").text = _t("THIS ROOK")
	get_node(^"Selected/Content/Row/Details/Apply").text = _t("Use Miniature")
	get_node(^"Selected/Content/Row/Details/Choose").text = _t("Choose Miniature")
	get_node(^"Selected/Content/Row/Details/Description").text = _t("Appearance for the selected Rook.")
