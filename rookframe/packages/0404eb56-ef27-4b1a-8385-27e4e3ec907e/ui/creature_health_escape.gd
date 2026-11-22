extends Node
## Escape closes the hit point editor at once, also while its amount is being typed.

signal pressed


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		pressed.emit()
