extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/defence_action.gd"

func _init(facade: SDK) -> void:
	super(facade)
	_operation = "melee"
	_active_states = ["ready", "pending", "shield", "fumble"]

func attack(input: Dictionary, creature: bool) -> void:
	if input.get("companion", false):
		_operation = "companion"
	elif creature:
		var result := await _submit("attack.validate", input)
		if not result.ok or str(result.value.get("state", "error")) != "ready":
			_accept(result)
			return
		_operation = "defence" if str(result.value.resolution) == "defence" else "melee"
	await start(input)

func choose(choice: String) -> void:
	if state in ["fumble", "shield"]:
		await _command("choose", {"choice": choice})

func _accept(result: SDK.DataResult) -> void:
	if result.ok and typeof(result.value) == TYPE_DICTIONARY:
		var value: Dictionary = result.value
		if not str(value.get("operation", "")).is_empty():
			_operation = str(value.operation)
		elif not str(value.get("defender", "")).is_empty():
			_operation = "defence"
	super._accept(result)
