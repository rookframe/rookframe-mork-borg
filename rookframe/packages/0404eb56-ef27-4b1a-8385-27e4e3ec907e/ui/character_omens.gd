extends VBoxContainer

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()
signal mutation_requested(operation: String, arguments: Array)
signal navigate_requested(route: String, item_id: String)
func configure(data: Dictionary, _miniatures: Array) -> void:
	var count: int = data.get("omens", 0)
	get_node(^"Omens/Content/Count").text = str(count)


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"Omens/Content/Available").text = _t("AVAILABLE")
	get_node(^"Omens/Content/Heading").text = _t("OMENS")
	get_node(^"Omens/Content/Hint").text = _t("Spending reduces the count by one.")
	get_node(^"Resolve/Content/Heading").text = _t("RESOLVE WITH THE TABLE")
	get_node(^"Resolve/Content/Help").text = _t("Resolve the benefit with your group. Make resulting corrections through ordinary rolls and sheet editing.")
