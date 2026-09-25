extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
## The live strip owns local view state; ordinary Resources carry its data.
const LOCAL_STATE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/encounter_local.gd")
var _local: LOCAL_STATE = LOCAL_STATE.new()

func encounter_view_state() -> LOCAL_STATE:
	return _local
