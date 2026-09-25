extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
const VIEW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_view.gd")
const CARD = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_portrait.tscn")
const SHEET = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/window_button.tres")
var _current := ""

func ready() -> void:
	resized.connect(_layout)
	if sdk != null:
		sdk.world_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if sdk == null:
		return
	var state: Dictionary = VIEW.new().snapshot(sdk)
	get_node(^"Panel").visible = not state.has("error") and bool(state.get("active", false))
	if get_node(^"Panel").visible == false:
		return
	get_node(^"Panel/Layout/Round").text = "ROUND %d · %s" % [int(state.round), "GROUP INITIATIVE" if state.mode == "group" else "INITIATIVE"]
	for child in get_node(^"Panel/Layout/Scroll/Portraits").get_children():
		get_node(^"Panel/Layout/Scroll/Portraits").remove_child(child)
		child.queue_free()
	var current: Control
	var rows: Array = state.rows
	for raw_row in rows:
		var row: Dictionary = raw_row
		var portrait: Texture2D = row.portrait
		var label: String = row.label
		var card: Button = CARD.instantiate()
		get_node(^"Panel/Layout/Scroll/Portraits").add_child(card)
		(card.get_node("Layout/Image") as TextureRect).texture = portrait
		(card.get_node("Layout/Name") as Label).text = label
		(card.get_node("Layout/Turn") as Label).text = "CURRENT" if row.active else ("PC" if row.side == "pc" else "ENEMY")
		card.set_pressed_no_signal(bool(row.active))
		card.tooltip_text = label + (" · current turn" if row.active else "")
		card.accessibility_name = card.tooltip_text
		card.pressed.connect(_open.bind(str(row.actor), bool(row.can_open)))
		if row.active:
			current = card
	_layout()
	if str(state.current) != _current and current != null:
		_current = str(state.current)
		await get_tree().process_frame
		if is_instance_valid(current):
			get_node(^"Panel/Layout/Scroll").ensure_control_visible(current)

func _layout() -> void:
	var available := maxf(144, size.x - 144)
	var desired := 32 + 76 * get_node(^"Panel/Layout/Scroll/Portraits").get_child_count()
	var width := minf(maxf(260, desired), minf(720, available))
	get_node(^"Panel").offset_left = -width / 2
	get_node(^"Panel").offset_right = width / 2

func _open(actor: String, allowed: bool) -> void:
	if allowed:
		sdk.windows.open_actor(SHEET.window, SDK.ActorId.new(actor))
