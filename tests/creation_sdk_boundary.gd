extends RefCounted

signal SettingsChanged
signal TargetingChanged
signal FeedbackActionSelected
signal SelectedRookContextChanged(context: Dictionary)
signal WorldChanged
signal TabletopCommandCompleted(result: Dictionary)
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
static var creation_serial := 0
var reject_creation := false
var defer_update := false
var pending_update: Dictionary = {}
var selected_rook := ""
var rooks: Dictionary = {}
var appearance_changes := 0
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

func ReadActor(id: String) -> Dictionary:
	for actor in actors:
		if actor.id == id:
			return {"ok": true, "value": actor.duplicate(true)}
	return {"ok": false, "message": "Actor unavailable."}

func UpdateActor(id: String, data: Variant) -> Dictionary:
	for actor in actors:
		if actor.id == id:
			if defer_update:
				pending_update = {"id": id, "data": data.duplicate(true)}
				return {"ok": false, "code": "pending", "requestId": 43}
			actor.data = data.duplicate(true)
			return {"ok": true, "value": actor.duplicate(true)}
	return {"ok": false, "message": "Actor unavailable."}

func SelectedRookContext() -> Dictionary:
	return {"id": selected_rook}

func complete_update() -> void:
	defer_update = false
	var result: Dictionary = UpdateActor(pending_update.id, pending_update.data)
	result["requestId"] = 43
	TabletopCommandCompleted.emit(result)

func ReadRook(id: String) -> Dictionary:
	return {"ok": true, "value": rooks[id].duplicate(true)} if rooks.has(id) else {"ok": false, "message": "Rook unavailable."}

func SetRookMiniature(id: String, package: String, miniature: String) -> Dictionary:
	appearance_changes += 1
	rooks[id].miniature = {"packageId": package, "localId": miniature}
	return ReadRook(id)

var defer_human := false
var pending_human: Dictionary = {}
var human_requests: Array[Dictionary] = []
var human_results: Dictionary = {}
var reports: Array[Dictionary] = []
var access_entries: Array[Dictionary] = []
var game_master := false
func WorldContext() -> Dictionary:
	return {"ok": true, "value": {"participant_id": "gm" if game_master else "player", "session_id": "session", "is_gm": game_master, "is_authority": game_master}}
func ListActorAccess(_id: String) -> Dictionary:
	return {"ok": true, "value": access_entries}
func RequestSessionThrow(id: String, participant: String, terms: Array) -> Dictionary:
	if not human_results.has(id):
		human_requests.append({"id": id, "participant": participant, "terms": terms.duplicate(true)})
		human_results[id] = {"status": "pending", "terms": [], "sequence": 0}
	var value: Dictionary = human_results[id].duplicate(true)
	value["request_id"] = id
	value["participant_id"] = participant
	value["plan"] = terms
	if defer_human:
		pending_human = {"ok": true, "value": value, "requestId": 44}
		return {"ok": false, "code": "pending", "requestId": 44}
	return {"ok": true, "value": value}
func complete_human() -> void:
	defer_human = false
	TabletopCommandCompleted.emit(pending_human)
func CancelHumanThrow(id: String) -> Dictionary:
	if human_results.has(id) and human_results[id].status == "pending":
		human_results[id].status = "cancelled"
	return {"ok": true, "value": human_results.get(id, {})}
func PublishActionLog(report: Dictionary) -> Dictionary:
	reports.append(report.duplicate(true))
	return {"ok": true, "value": {"sequence": reports.size() + 42}}
