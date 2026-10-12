extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")

func _host() -> BOUNDARY:
	var host := BOUNDARY.new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	return host

func _attack_input(id: String) -> Dictionary:
	return {"id": id, "source": "hero", "rook": "hero-rook", "item": "1", "tabletop": true}

func test_no_target_and_preselected_outside_reach_do_not_request_dice() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	host.targets = PackedStringArray()
	var result := await sdk.system_actions.submit("melee.start", _attack_input("none"))
	assert_str(result.value.state).is_equal("error")
	assert_bool(host.requests.is_empty()).is_true()
	host.targets = PackedStringArray(["enemy-rook"])
	host.distance = 1.52401
	result = await sdk.system_actions.submit("melee.start", _attack_input("outside"))
	assert_str(result.value.state).is_equal("error")
	assert_bool(host.requests.is_empty()).is_true()

func test_weapon_property_and_target_dr_override_untrusted_window_values() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	host.actors.enemy.data["piercing_defence_dr"] = 14
	host.actors.hero.data.inventory[0]["piercing"] = true
	var input := _attack_input("piercing")
	input.merge({"difficulty": 1, "modifier": 20, "piercing": false})
	var started := await sdk.system_actions.submit("melee.start", input)
	assert_bool(started.value.has("difficulty")).is_false()
	assert_int(host.requests.piercing.result.base_modifier).is_equal(-1)
	assert_bool(host.requests.piercing.result.allow_modifier).is_true()
	host.roll("piercing", [14])
	var result := await sdk.system_actions.submit("melee.advance", {"id": "piercing"})
	assert_str(result.value.state).is_equal("resolved")
	assert_str(host.reports[-1].result).is_equal("Miss")
	assert_int(host.requests.size()).is_equal(1)

func test_accepted_tray_modifier_is_applied_exactly_once() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("melee.start", _attack_input("adjusted"))
	host.roll("adjusted", [12])
	# Ability -1 plus situation +1 gives accepted total zero.
	host.requests.adjusted.result.modifier = 0
	await sdk.system_actions.submit("melee.advance", {"id": "adjusted"})
	assert_int(host.requests.size()).is_equal(2)
	assert_int(host.requests[host.last_request].result.base_modifier).is_equal(0)
	assert_bool(host.requests[host.last_request].result.allow_modifier).is_false()

func test_moving_target_out_of_reach_ends_before_applying_damage() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("melee.start", _attack_input("moving"))
	host.roll("moving", [18])
	await sdk.system_actions.submit("melee.advance", {"id": "moving"})
	host.roll(host.last_request, [6, 1])
	host.distance = 2.0
	var result := await sdk.system_actions.submit("melee.advance", {"id": "moving"})
	assert_str(result.value.state).is_equal("ended")
	assert_int(host.actors.enemy.data.hit_points).is_equal(6)

func test_remote_gm_resolves_fumble_after_roll_once() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("melee.start", _attack_input("fumble-gm"))
	host.roll("fumble-gm", [1])
	await sdk.system_actions.submit("melee.advance", {"id": "fumble-gm"})
	host.access_entries = [{"participant_id": "player", "display_name": "Player", "session_id": "player-session", "access_level": "Owner", "is_connected": true}]
	host.game_master = true
	host.participant = "gm"
	host.session = "gm-session"
	var inbox := await sdk.system_actions.submit("melee.inbox", {})
	assert_int(inbox.value.size()).is_equal(1)
	var result := await sdk.system_actions.submit("melee.advance", {"id": "fumble-gm"})
	assert_str(result.value.state).is_equal("fumble")
	await sdk.system_actions.submit("melee.choose", {"id": "fumble-gm", "choice": "break"})
	await sdk.system_actions.submit("melee.choose", {"id": "fumble-gm", "choice": "lose"})
	assert_int(host.actors.hero.data.inventory.size()).is_equal(1)
	assert_bool(host.actors.hero.data.inventory[0].broken).is_true()
	assert_int(host.reports.size()).is_equal(1)

func test_fumble_ends_when_initiating_session_is_replaced() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	await sdk.system_actions.submit("melee.start", _attack_input("stale-fumble"))
	host.roll("stale-fumble", [1])
	await sdk.system_actions.submit("melee.advance", {"id": "stale-fumble"})
	host.sessions[0].session_id = "replacement"
	host.participant = "gm"
	host.session = "gm-session"
	host.game_master = true
	var result := await sdk.system_actions.submit("melee.choose", {"id": "stale-fumble", "choice": "break"})
	assert_str(result.value.state).is_equal("ended")
	assert_bool(host.actors.hero.data.inventory[0].get("broken", false)).is_false()
	assert_int(host.reports.size()).is_equal(1)
	assert_str(host.reports[0].result).is_equal("ENDED")

func test_authored_creature_weapons_keep_piercing_when_inventory_is_built() -> void:
	var definition = load(ROOT + "content/belze-skeleton.tres")
	var data: Dictionary = definition.create_data({})
	var attacks: Array = definition.combat_attacks(data)
	assert_bool(attacks[0].piercing).is_true()
	assert_bool(attacks[1].piercing).is_true()
	assert_bool(attacks[2].get("piercing", false)).is_false()

func test_saved_creature_uses_missing_authored_property_without_overwriting_false() -> void:
	var definition = load(ROOT + "content/belze-skeleton.tres")
	var data: Dictionary = definition.create_data({})
	data.attacks[0].erase("piercing")
	data.attacks[1].piercing = false
	data.attacks.append({"id": "custom-knife", "name": "Knife", "dice": "d4", "range_feet": 5})
	var attacks: Array = definition.combat_attacks(data)
	assert_bool(attacks[0].piercing).is_true()
	assert_bool(attacks[1].piercing).is_false()
	assert_bool(attacks[3].get("piercing", false)).is_false()
	assert_bool(data.attacks[0].has("piercing")).is_false()

class InboxHost:
	extends "res://tests/melee_sdk_boundary.gd"
	var window_busy := true
	var opened_actors: Array[String] = []
	func WorldContext() -> Dictionary:
		return {"ok": true, "value": {"is_authority": false, "is_gm": false, "participant_id": "player", "session_id": "player-session"}}
	func SubmitSystemIntent(_operation: String, _payload: Variant) -> Dictionary:
		return {"ok": true, "value": [{"id": "waiting-defence", "state": "ready", "initiator": "gm", "target": "second-character"}]}
	func OpenActorTaskWindowWithPresentation(_scene: PackedScene, actor: String, _presentation: Dictionary, _task: Dictionary) -> Dictionary:
		opened_actors.append(actor)
		return {"ok": not window_busy}

func test_incoming_request_retries_after_another_characters_window_closes() -> void:
	var host := InboxHost.new()
	var presentation = auto_free(preload(ROOT + "ui/presentation.gd").new())
	presentation.sdk = SDK.new(host)
	await presentation._check_defences()
	assert_bool(presentation._seen_defences.has("waiting-defence")).is_false()
	host.window_busy = false
	await presentation._check_defences()
	assert_bool(presentation._seen_defences.has("waiting-defence")).is_true()
	await presentation._check_defences()
	assert_array(host.opened_actors).is_equal(["second-character", "second-character"])

func test_incoming_consequence_has_separate_managed_window_identity() -> void:
	var attack = load(ROOT + "ui/tabletop_attack_surface.tres")
	var consequence = load(ROOT + "ui/tabletop_consequence_surface.tres")
	assert_str(attack.scene.resource_path).is_not_equal(consequence.scene.resource_path)
