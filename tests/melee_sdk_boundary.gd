extends RefCounted
signal SettingsChanged
signal TargetingChanged
signal FeedbackActionSelected
signal WorldChanged
signal TabletopCommandCompleted(result: Dictionary)
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
var handler: Node
var actors := {
 "hero": {"id": "hero", "access_level": "Owner", "public_label": "", "data": {"schema": "mork-borg-character/v1", "name": "Graveworm", "abilities": {"Strength": {"modifier": -1}}, "inventory": [{"inventory_id": "1", "source_item_id": "sword", "name": "Sword", "kind": "Weapon", "damage": "d6", "range_feet": 5, "quantity": 1, "equipped": true}]}},
 "enemy": {"id": "enemy", "access_level": "None", "public_label": "Hooded stranger", "data": {"schema": "mork-borg-adversary/v1", "name": "Seth, Goblin", "hit_points": 6, "armor": {"reduction": "d2"}}}
}
var rooks := {"hero-rook": "hero", "enemy-rook": "enemy"}
var targets := PackedStringArray(["enemy-rook"])
var distance := 1.2192
var distances: Dictionary = {}
var requests: Dictionary = {}
var reports: Array = []
var request_serial := 0
var session := "player-session"
var participant := "player"
var game_master := false
var access_entries: Array = []
var fail_commit := false
var active := false
var last_request := ""
var defer_reply := false
var queued_reply: Dictionary = {}
var transient_failures: Dictionary = {}
var submissions: Dictionary = {}
func PackageId() -> String:
 return "0404eb56-ef27-4b1a-8385-27e4e3ec907e"
func NewHumanThrowRequestId() -> String:
 request_serial += 1
 return "damage-%d" % request_serial
func SubmitSystemIntent(name: String, data: Variant) -> Dictionary:
 submissions[name] = int(submissions.get(name, 0)) + 1
 if int(transient_failures.get(name, 0)) > 0:
  transient_failures[name] -= 1
  return {"ok": false, "code": "rate_limited", "message": "Retry later"}
 active = true
 var outcome: Variant = handler.handle_system_intent(SDK.SystemActionContext.new(self, "active"), name, data)
 active = false
 var reply := {"ok": true, "value": outcome}
 if defer_reply:
  defer_reply = false
  queued_reply = reply
  queued_reply["requestId"] = 42
  return {"ok": false, "code": "pending", "requestId": 42}
 return reply
func complete_reply() -> void:
 TabletopCommandCompleted.emit(queued_reply)
func SystemIntentContext(_token: String) -> Dictionary:
 return {"ok": active, "value": {"participant_id": participant, "session_id": session, "display_name": "Player", "is_gm": game_master, "is_authority": true, "targets": targets}}
func SystemIntentReadActor(_token: String, id: String) -> Dictionary:
 return {"ok": true, "value": actors[id].duplicate(true)} if actors.has(id) else {"ok": false, "message": "Actor unavailable"}
func SystemIntentReadRook(_token: String, id: String) -> Dictionary:
 return {"ok": true, "value": {"id": id, "actor": rooks[id], "scene": "main", "position": Vector2.ZERO, "yaw": 0.0, "miniature": {"packageId": "", "localId": ""}}} if rooks.has(id) else {"ok": false}
func SystemIntentActorAccess(_token: String, _id: String) -> Dictionary:
 return {"ok": true, "value": access_entries}
func SystemIntentDistance(_token: String, _from: String, _to: String) -> Dictionary:
 return {"ok": true, "value": distances.get(_to, distance)}
func SystemIntentReadThrow(_token: String, id: String) -> Dictionary:
 return {"ok": true, "value": requests[id].result.duplicate(true)} if requests.has(id) else {"ok": false}
func SystemIntentRequestThrow(token: String, id: String, target: String, terms: Array) -> Dictionary:
 for term in terms:
  if not term.faces in [4, 6, 8, 10, 12, 20]:
   return {"ok": false, "message": "Unsupported physical die"}
 if not requests.has(id):
  requests[id] = {"participant": target, "terms": terms.duplicate(true), "result": {"request_id": id, "participant_id": target, "status": "pending", "plan": terms.duplicate(true), "terms": [], "sequence": 0}}
 last_request = id
 return SystemIntentReadThrow(token, id)
func SystemIntentCancelThrow(token: String, id: String) -> Dictionary:
 if requests.has(id) and requests[id].result.status == "pending":
  requests[id].result.status = "cancelled"
 return SystemIntentReadThrow(token, id)
func SystemIntentCommit(_token: String, changes: Array, report: Dictionary) -> Dictionary:
 if str(report.get("title", "")).to_utf16_buffer().size() / 2 > 72:
  return {"ok": false, "message": "Title too long"}
 if fail_commit:
  return {"ok": false, "message": "Save failed"}
 for change in changes:
  actors[change.id].data = change.data.duplicate(true)
 if not report.is_empty():
  reports.append(report.duplicate(true))
 return {"ok": true}
func roll(id: String, values: Array) -> void:
 var request: Dictionary = requests[id]
 var terms: Array = []
 var index := 0
 for term in request.terms:
  var results: Array = []
  for _die in int(term.count):
   results.append(values[index])
   index += 1
  terms.append({"name": term.name, "faces": term.faces, "results": results})
 request.result.terms = terms
 request.result.status = "rolled"
 request.result.sequence = requests.size()
