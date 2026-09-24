extends Window
signal choice_requested(choice: String)
signal cancelled

func _ready() -> void:
	close_requested.connect(_cancel)
	get_node(^"Shell/Content/Header/Close").pressed.connect(_cancel)
	get_node(^"Shell/Content/Actions/Take").pressed.connect(_choose.bind("take"))
	get_node(^"Shell/Content/Actions/Break").pressed.connect(_choose.bind("break"))

func present(outcome: Dictionary) -> void:
	var loss: int = outcome.loss
	var hp: int = outcome.hp
	get_node(^"Shell/Content/Body/Copy").text = "%s will take %d damage (%d → %d HP).\n\nBreak your shield to take no damage instead." % [str(outcome.character), loss, hp, hp - loss]
	get_node(^"Shell/Content/Actions/Take").text = "Take %d damage" % loss
	if not visible:
		popup_centered()
		get_node(^"Shell/Content/Actions/Take").grab_focus()

func set_pending(value: bool) -> void:
	get_node(^"Shell/Content/Actions/Take").disabled = value
	get_node(^"Shell/Content/Actions/Break").disabled = value

func dismiss() -> void:
	hide()

func _choose(choice: String) -> void:
	set_pending(true)
	choice_requested.emit(choice)

func _cancel() -> void:
	dismiss()
	cancelled.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_cancel()
		set_input_as_handled()
