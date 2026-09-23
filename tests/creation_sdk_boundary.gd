extends RefCounted

signal SettingsChanged
signal TargetingChanged
signal FeedbackActionSelected
signal WorldChanged
signal TabletopCommandCompleted(result: Dictionary)
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
static var creation_serial := 0
var reject_creation := false
var pending_roll := ""
var pending_result: Dictionary = {}
var outcomes: Dictionary = {}
var requests: Array[Dictionary] = []
var actors: Array[Dictionary] = []
var errors: Array[String] = []

func PackageId() -> String:
	return "0404eb56-ef27-4b1a-8385-27e4e3ec907e"

func RollDice(terms: Array) -> Dictionary:
	var term: Dictionary = terms[0]
	requests.append(term.duplicate(true))
	var name: String = str(term.name).split(" (d2:")[0]
	if not outcomes.has(name) or outcomes[name].is_empty():
		errors.append("Unexpected roll: " + name)
		return {"ok": false, "message": "No supplied outcome for " + name}
	var values: Array = outcomes[name].pop_front()
	if values.size() != int(term.count):
		errors.append("Wrong dice count for " + name)
	for value in values:
		if int(value) < 1 or int(value) > int(term.faces):
			errors.append("Wrong die size for " + name)
	var result := {"ok": true, "value": {"sequence": requests.size(), "terms": [{"name": term.name, "faces": term.faces, "results": values}]}}
	if name == pending_roll:
		pending_result = result
		pending_result["requestId"] = 42
		return {"ok": false, "code": "pending", "requestId": 42}
	return result

func complete_pending() -> void:
	TabletopCommandCompleted.emit(pending_result)

func CreateActorsAtomically(_package: String, definition: String, choices: Variant, children: Array) -> Dictionary:
	if reject_creation:
		return {"ok": false, "message": "The World rejected the creation bundle."}
	var definition_resource = load(ROOT + "content/" + definition + ".tres")
	var actor := {"id": "character", "access_level": "Owner", "data": definition_resource.create_data(choices)}
	actors.append(actor)
	for child in children:
		var resource = load(ROOT + "content/" + str(child.local_id) + ".tres")
		actors.append({"id": "child-%d" % actors.size(), "access_level": "Owner", "data": resource.create_data(child.choices)})
	return {"ok": true, "value": actor}

func ListActors() -> Dictionary:
	return {"ok": true, "value": actors}


func NewHumanThrowRequestId() -> String:
	creation_serial += 1
	return "33333333-3333-4333-8333-%012d" % creation_serial
