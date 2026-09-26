extends VBoxContainer

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()

const TITLES := ["Class", "Abilities", "Origin & Traits", "Equipment", "Identity", "Review"]

func present_progress(step: int, compact: bool) -> void:
	get_node(^"Wide").visible = not compact
	get_node(^"Compact").visible = compact
	get_node(^"Compact/Label").text = "%d / 6 · %s" % [step, _t(TITLES[step - 1]).to_upper()]
	get_node(^"Compact/Track").value = step
	for index in range(6):
		var cell := get_node(^"Wide").get_child(index) as VBoxContainer
		var underline := cell.get_node(^"Underline") as ProgressBar
		underline.visible = index + 1 == step
		var marker := cell.get_node(^"MarkerRow/Circle/Marker") as Label
		var title := cell.get_node(^"Title") as Label
		marker.text = "✓" if index + 1 < step else str(index + 1)
		marker.theme_type_variation = "RookframeValue" if index + 1 <= step else "RookframeMeta"
		title.theme_type_variation = "RookframeValue" if index + 1 <= step else "RookframeMeta"
	accessibility_name = _t("Step %d of 6: %s") % [step, _t(TITLES[step - 1])]


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"Compact/Label").text = _t("1 / 6 · CLASS")
	get_node(^"Wide/Step1/Title").text = _t("Class")
	get_node(^"Wide/Step2/Title").text = _t("Abilities")
	get_node(^"Wide/Step3/Title").text = _t("Origin & Traits")
	get_node(^"Wide/Step4/Title").text = _t("Equipment")
	get_node(^"Wide/Step5/Title").text = _t("Identity")
	get_node(^"Wide/Step6/Title").text = _t("Review")
