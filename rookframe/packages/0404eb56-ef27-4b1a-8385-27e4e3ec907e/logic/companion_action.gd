extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/defence_action.gd"
## The first authority response fixes the existing melee or defence workflow.
func _init(facade: SDK) -> void:
	super(facade)
	_operation = "companion"

func _accept(result: SDK.DataResult) -> void:
	if result.ok:
		var outcome: Dictionary = result.value
		if str(outcome.get("operation", "")) in ["melee", "defence"]:
			_operation = str(outcome.operation)
	super._accept(result)
