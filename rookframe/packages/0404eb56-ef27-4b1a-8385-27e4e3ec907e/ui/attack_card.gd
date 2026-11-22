extends VBoxContainer
## Mörk Borg content and callbacks composed in the public Action Panel slots.
signal prepare
signal close_requested
signal target_requested
signal decision(choice: int)
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/"
const DICE_ICONS := {
	"d4": preload(ROOT + "attack_assets/icons/d4.svg"),
	"d6": preload(ROOT + "attack_assets/icons/d6.svg"),
	"d8": preload(ROOT + "attack_assets/icons/d8.svg"),
	"d10": preload(ROOT + "attack_assets/icons/d10.svg"),
	"d12": preload(ROOT + "attack_assets/icons/d12.svg"),
	"d20": preload(ROOT + "attack_assets/icons/d20.svg"),
}
const FRAME = preload("res://rookframe/ui/components/surfaces/action_panel/action_panel.gd")
@onready var _frame: FRAME = get_node("Frame")
const I18N = preload(ROOT + "localization.gd")
var _locale := I18N.new()
const TOKENS := &"RookframeTokens"
## Tallest touch card that leaves the tabletop usable; a layout bound, not a themed size.
const TOUCH_HEIGHT := 260.0
var _target_valid := true
var _distance_ink: StringName = &"content_muted"
var _message_ink: StringName = &"content"
@onready var body: VBoxContainer = get_node("Frame/Sections/SectionsSlot/Section/Body")
var _device := ""
var _roomy_rows := false
var _fit_queued := false
@onready var _view_combat: BoxContainer = get_node("Frame/Sections/SectionsSlot/Section/Body/Combat")
@onready var _view_combat_attack: HBoxContainer = get_node("Frame/Sections/SectionsSlot/Section/Body/Combat/Attack")
@onready var _view_combat_attack_roll: Button = get_node("Frame/Sections/SectionsSlot/Section/Body/Combat/Attack/Roll")
@onready var _view_combat_attack_values_formula: Label = get_node("Frame/Sections/SectionsSlot/Section/Body/Combat/Attack/Values/Formula")
@onready var _view_combat_attack_values_label: Label = get_node("Frame/Sections/SectionsSlot/Section/Body/Combat/Attack/Values/Label")
@onready var _view_combat_damage_icon: TextureRect = get_node("Frame/Sections/SectionsSlot/Section/Body/Combat/Damage/Icon")
@onready var _view_combat_damage_values_formula: Label = get_node("Frame/Sections/SectionsSlot/Section/Body/Combat/Damage/Values/Formula")
@onready var _view_combat_damage_values_label: Label = get_node("Frame/Sections/SectionsSlot/Section/Body/Combat/Damage/Values/Label")
@onready var _view_combat_damagedivider: HSeparator = get_node("Frame/Sections/SectionsSlot/Section/Body/Combat/DamageDivider")
@onready var _view_decision: HBoxContainer = get_node("Frame/Sections/SectionsSlot/Section/Body/Decision")
@onready var _view_decision_first: Button = get_node("Frame/Sections/SectionsSlot/Section/Body/Decision/First")
@onready var _view_decision_second: Button = get_node("Frame/Sections/SectionsSlot/Section/Body/Decision/Second")
@onready var _view_header: HBoxContainer = get_node("Frame/Header/Leaf/HeaderSlot/Header")
@onready var _view_header_close: Button = get_node("Frame/Header/Leaf/HeaderSlot/Header/Close")
@onready var _view_header_identity_actor: Label = get_node("Frame/Header/Leaf/HeaderSlot/Header/Identity/Actor")
@onready var _view_header_identity_reach: Label = get_node("Frame/Header/Leaf/HeaderSlot/Header/Identity/Reach")
@onready var _view_header_identity_title: Label = get_node("Frame/Header/Leaf/HeaderSlot/Header/Identity/Title")
@onready var _view_header_weapon: TextureRect = get_node("Frame/Header/Emblem/Leaf/EmblemSlot/Weapon")
@onready var _view_message: Label = get_node("Frame/Sections/SectionsSlot/Section/Body/Message")
@onready var _view_target: HBoxContainer = get_node("Frame/Footer/Leaf/FooterSlot/Target")
@onready var _view_target_change: Button = get_node("Frame/Footer/Leaf/FooterSlot/Target/Change")
@onready var _view_target_distance: Label = get_node("Frame/Footer/Leaf/FooterSlot/Target/Distance")
@onready var _view_target_icon: TextureRect = get_node("Frame/Footer/Leaf/FooterSlot/Target/Icon")
@onready var _view_target_name: Label = get_node("Frame/Footer/Leaf/FooterSlot/Target/Name")

func _ready() -> void:
	(_view_header_close as Button).pressed.connect(_close_requested)
	(_view_target_change as Button).pressed.connect(_target_requested)
	(_view_combat_attack_roll as Button).pressed.connect(_prepare_requested)
	(_view_decision_first as Button).pressed.connect(_first_decision)
	(_view_decision_second as Button).pressed.connect(_second_decision)
	responsive("desktop")
	_read_tokens()

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_read_tokens()

# Pictograms take the World theme's ornament ink, and an out-of-reach target its
# danger ink. Tinting children does not notify this container again.
func _read_tokens() -> void:
	var ornament := get_theme_color(&"ornament", TOKENS)
	for icon in [_view_header_weapon, _view_combat_attack.get_node("Icon"), _view_combat_damage_icon]:
		(icon as Control).self_modulate = ornament
	_view_target_icon.self_modulate = ornament if _target_valid else get_theme_color(&"danger", TOKENS)
	_apply_roles()

# Every theme's Action Panel presentation may put its own Theme between these
# labels and the World theme, which hides the World theme's label variations.
# Each label therefore reads its type role and ink from RookframeTokens.
# Touch layouts step each type role down instead of shrinking pixels.
func _apply_roles() -> void:
	if not is_inside_tree():
		return
	var touch := _device != "desktop"
	_role(_view_header_identity_actor, &"meta", &"content_muted")
	_role(_view_header_identity_title, &"heading" if touch else &"title", &"content_heading")
	_role(_view_header_identity_reach, &"meta" if touch else &"body", &"content_muted")
	_row_roles(touch and not (_device == "tablet" and _roomy_rows))
	_role(_view_target_name, &"meta" if _device == "phone" else &"body", &"content")
	_role(_view_target_distance, &"meta", _distance_ink)
	_role(_view_message, &"body", _message_ink)
	if _device == "tablet" and not _fit_queued:
		_fit_queued = true
		_fit_rows.call_deferred()

# A tablet's rows take the larger type where the theme's scale leaves the card
# inside its touch height. The UI Kit frame takes its compact form over the
# next frames, so the card is measured after them, without its message.
func _fit_rows() -> void:
	for frame in range(2):
		if is_inside_tree():
			await get_tree().process_frame
	_fit_queued = false
	if not is_inside_tree() or _device != "tablet" or not _view_combat.visible:
		return
	var least := _view_combat_attack_roll.custom_minimum_size.y
	var extra := maxf(_line(&"label") + _line(&"value"), least) - maxf(_line(&"meta") + _line(&"heading"), least)
	var height := get_combined_minimum_size().y - (extra if _roomy_rows else 0.0)
	if _view_message.visible:
		height -= _view_message.get_combined_minimum_size().y + body.get_theme_constant(&"separation")
	var roomy := height + extra <= TOUCH_HEIGHT
	if roomy != _roomy_rows:
		_roomy_rows = roomy
		_row_roles(not roomy)

func _line(type_role: StringName) -> float:
	return get_theme_font(type_role, TOKENS).get_height(get_theme_font_size(type_role, TOKENS))

func _row_roles(small: bool) -> void:
	for row in ["Attack", "Damage"]:
		var line: HBoxContainer = body.get_node("Combat/" + row)
		_role(line.get_node("Values/Label") as Label, &"meta" if small else &"label", &"content_muted")
		_role(line.get_node("Values/Formula") as Label, &"heading" if small else &"value", &"content")

func _role(label: Label, type_role: StringName, ink: StringName) -> void:
	label.add_theme_font_override(&"font", get_theme_font(type_role, TOKENS))
	label.add_theme_font_size_override(&"font_size", get_theme_font_size(type_role, TOKENS))
	label.add_theme_color_override(&"font_color", get_theme_color(ink, TOKENS))

func responsive(device: String) -> void:
	if device == _device:
		return
	_device = device
	var touch := device != "desktop"
	var phone := device == "phone"
	_frame.compact = touch
	custom_minimum_size = Vector2(320 if phone else 380 if touch else 520, 0)
	_view_header_weapon.custom_minimum_size = Vector2(30,30) if touch else Vector2(42,42)
	_view_combat.vertical = not touch
	_view_combat.set(&"gap", &"space_4" if touch else &"")
	_view_combat_attack.size_flags_horizontal = 1 if touch else Control.SIZE_EXPAND_FILL # Native SIZE_FILL, without expansion.
	_view_combat_damagedivider.visible = not touch
	for row in ["Attack", "Damage"]:
		var line: HBoxContainer = body.get_node("Combat/" + row)
		# A touch row is as tall as its stacked label and formula in the theme's type.
		line.custom_minimum_size = Vector2(0, 0 if touch else 66 if row == "Attack" else 54)
		line.set(&"gap", &"space_1" if touch else &"space_4")
		(line.get_node("Icon") as TextureRect).custom_minimum_size = Vector2(24,24) if touch else Vector2(36,36)
		(line.get_node("Values") as BoxContainer).vertical = touch
		line.alignment = 2 if touch and row == "Damage" else 0 # Native end/begin alignment.
		(line.get_node("Values") as BoxContainer).size_flags_horizontal = 1 if touch else Control.SIZE_EXPAND_FILL
		(line.get_node("Values") as BoxContainer).set(&"gap", &"" if touch else &"space_4")
		(line.get_node("Values/Label") as Label).custom_minimum_size = Vector2(0 if touch else 110, 0)
	_view_target_icon.custom_minimum_size = Vector2(26,26) if touch else Vector2(32,32)
	_apply_roles()

func show_target(visible: bool) -> void:
	_frame.show_footer = visible

func localize(locale: I18N) -> void:
	_locale = locale
	_view_header_close.accessibility_name = _locale.text("Close")
	_view_header_close.tooltip_text = _locale.text("Close")

func identity(actor: String, weapon: String, detail: String, shield := false) -> void:
	_view_header_identity_actor.text = actor
	_view_header_identity_title.text = _locale.text(weapon)
	_view_header_identity_reach.text = detail
	_view_header_weapon.texture = load(ROOT + "attack_assets/icons/shield.svg" if shield else ROOT + "attack_assets/icons/weapon.svg")

func combat(formula: String, damage: String, can_prepare: bool, caption := "Attack", on_failure := false) -> void:
	_view_combat.visible = true
	_view_combat_attack.visible = not formula.is_empty()
	_view_combat_damagedivider.visible = _device == "desktop" and not formula.is_empty()
	_view_combat_attack_values_label.text = _locale.text(caption)
	_view_combat_attack_values_formula.text = formula
	_view_combat_damage_values_formula.text = damage
	_view_combat_damage_values_label.text = _locale.text(("On fail" if on_failure else "On hit") if _device != "desktop" else ("Damage · on fail" if on_failure else "Damage · on hit"))
	var die := damage.trim_prefix("1").split("+")[0]
	if DICE_ICONS.has(die):
		_view_combat_damage_icon.texture = DICE_ICONS.get(die)
	for path in ["Combat/Attack/Roll"]:
		var button: Button = body.get_node(path)
		button.disabled = not can_prepare
		button.accessibility_name = _locale.text("Prepare defence" if caption == "Defence" else "Prepare attack")
		button.tooltip_text = button.accessibility_name

func target(name: String, distance: String, valid: bool, editable: bool) -> void:
	_frame.show_footer = true
	_view_target_name.text = _locale.text(name)
	_view_target_distance.text = distance
	_target_valid = valid or distance.is_empty()
	_distance_ink = &"content_muted" if valid else &"danger"
	if is_node_ready():
		_read_tokens()
	_view_target_change.disabled = not editable
	_view_target_change.accessibility_name = _locale.text("Choose target")
	_view_target_change.tooltip_text = _locale.text("Choose target")

func message(text: String, error := false) -> void:
	_view_message.text = _locale.text(text)
	_view_message.visible = not text.is_empty()
	_message_ink = &"danger" if error else &"content"
	_apply_roles()

func consequence(first: String, second: String, enabled := true) -> void:
	_view_combat.visible = false
	_frame.show_footer = false
	_view_decision.visible = not first.is_empty()
	_view_decision_first.text = _locale.text(first)
	_view_decision_second.text = _locale.text(second)
	_view_decision_second.visible = not second.is_empty()
	_view_decision_first.disabled = not enabled
	_view_decision_second.disabled = not enabled

func request_defence(enabled: bool) -> void:
	_view_decision.visible = true
	_view_decision_first.text = _locale.text("Request defence")
	_view_decision_first.disabled = not enabled
	_view_decision_second.visible = false

func _close_requested() -> void:
	close_requested.emit()
func _target_requested() -> void:
	target_requested.emit()
func _prepare_requested() -> void:
	prepare.emit()
func _first_decision() -> void:
	decision.emit(0)
func _second_decision() -> void:
	decision.emit(1)
