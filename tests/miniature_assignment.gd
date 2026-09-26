extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const ACTIONS = preload(ROOT + "logic/miniature_actions.gd")
const BOUNDARY = preload("res://tests/miniature_boundary.gd")
const GOBLIN := {"package_id": "external-miniatures", "local_id": "goblin"}
const WARDEN := {"package_id": "external-miniatures", "local_id": "warden"}

func _host() -> BOUNDARY:
	var host := BOUNDARY.new()
	host.game_master = true
	host.participant = "gm"
	host.handler = auto_free(SYSTEM.new())
	host.handler.sdk = SDK.new(host)
	add_child(host.handler)
	return host

func test_world_default_is_copied_only_to_new_creatures_and_survives_new_implementation() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var saved := await sdk.system_actions.submit("miniature.default", {"definition": "seth-goblin", "package_id": GOBLIN.package_id, "local_id": GOBLIN.local_id})
	assert_str(saved.value.state).is_equal("resolved")
	var first := await sdk.system_actions.submit("miniature.create", {"definition": "seth-goblin"})
	assert_str(first.value.state).is_equal("resolved")
	var first_id := SDK.ActorId.new(str(first.value.actor))
	assert_dict(sdk.actors.read(first_id).actor.data.preferred_miniature).is_equal(GOBLIN)
	await sdk.system_actions.submit("miniature.default", {"definition": "seth-goblin", "package_id": WARDEN.package_id, "local_id": WARDEN.local_id})
	host.handler = auto_free(SYSTEM.new())
	host.handler.sdk = sdk
	add_child(host.handler)
	var second := await sdk.system_actions.submit("miniature.create", {"definition": "seth-goblin"})
	assert_dict(sdk.actors.read(SDK.ActorId.new(str(second.value.actor))).actor.data.preferred_miniature).is_equal(WARDEN)
	assert_dict(sdk.actors.read(first_id).actor.data.preferred_miniature).is_equal(GOBLIN)
	assert_str(sdk.world_data.read().value.unrelated).is_equal("retained")
	await sdk.system_actions.submit("miniature.default", {"definition": "seth-goblin", "package_id": "", "local_id": ""})
	var third := await sdk.system_actions.submit("miniature.create", {"definition": "seth-goblin"})
	assert_dict(sdk.actors.read(SDK.ActorId.new(str(third.value.actor))).actor.data.preferred_miniature).is_equal({"package_id": "fbf21a78-626e-4f35-b2ce-bd196083d9b7", "local_id": "goblin"})

func test_refusals_preserve_world_defaults_and_actor_choice() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	host.game_master = false
	var rejected := await sdk.system_actions.submit("miniature.default", {"definition": "seth-goblin", "package_id": GOBLIN.package_id, "local_id": GOBLIN.local_id})
	assert_str(rejected.value.state).is_equal("error")
	host.game_master = true
	host.fail_commit = true
	rejected = await sdk.system_actions.submit("miniature.default", {"definition": "seth-goblin", "package_id": GOBLIN.package_id, "local_id": GOBLIN.local_id})
	assert_str(rejected.value.state).is_equal("error")
	assert_dict(sdk.world_data.read().value).is_equal({"unrelated": "retained"})
	host.fail_commit = false
	host.missing = true
	rejected = await sdk.system_actions.submit("miniature.default", {"definition": "seth-goblin", "package_id": GOBLIN.package_id, "local_id": GOBLIN.local_id})
	assert_str(rejected.value.state).is_equal("error")
	var actions := ACTIONS.new(sdk)
	var id := SDK.ActorId.new("enemy")
	assert_bool((await actions.set_actor(id, GOBLIN)).ok).is_false()
	host.actors.enemy.access_level = "Owner"
	assert_bool((await actions.set_actor(id, GOBLIN)).ok).is_false()
	assert_bool((await actions.place(id)).ok).is_false()
	assert_dict(host.placed).is_empty()

func test_external_actor_choice_places_in_current_scene_and_changes_only_selected_rook() -> void:
	var host := _host()
	var sdk := SDK.new(host)
	var id := SDK.ActorId.new("enemy")
	host.actors.enemy.access_level = "Owner"
	var actions := ACTIONS.new(sdk)
	assert_bool((await actions.set_actor(id, GOBLIN)).ok).is_true()
	var first := await actions.place(id)
	var second := await actions.place(id)
	assert_bool(first.ok and second.ok).is_true()
	assert_str(first.rook.scene.value).is_equal("chosen-scene")
	assert_str(first.rook.miniature.package_id).is_equal("external-miniatures")
	host.placed[first.rook.id.value].hidden = true
	assert_bool((await actions.set_actor(id, WARDEN)).ok).is_true()
	assert_str(sdk.rooks.read(first.rook.id).rook.miniature.local_id).is_equal("goblin")
	host.selected_rook = first.rook.id.value
	assert_bool((await actions.apply_selected(id)).ok).is_true()
	assert_str(sdk.rooks.read(first.rook.id).rook.miniature.local_id).is_equal("warden")
	assert_bool(sdk.rooks.read(first.rook.id).rook.hidden).is_true()
	assert_str(sdk.rooks.read(second.rook.id).rook.miniature.local_id).is_equal("goblin")

func test_picker_russian_selection_cancel_and_failed_save_keep_actor_unchanged() -> void:
	var host := _host()
	host.language = "ru"
	var sdk := SDK.new(host)
	var locale = load(ROOT + "ui/localization.gd").new()
	locale.bind(sdk)
	host.actors.enemy.access_level = "Owner"
	var view = auto_free(load(ROOT + "ui/miniature_workflow.tscn").instantiate())
	add_child(view)
	view.size = Vector2(351, 321)
	view.open(sdk, locale, SDK.ActorId.new("enemy"), "", {})
	assert_str(view.browser.get_node("Search").placeholder_text).is_equal("Поиск миниатюр")
	assert_str(view.browser.get_node("Results/Rows").get_child(0).get_node("Copy/Title").text).contains("Чужой гоблин")
	view.browser.get_node("Results/Rows").get_child(0).pressed.emit()
	view.get_node("Actions/Back").pressed.emit()
	assert_bool(host.actors.enemy.data.has("preferred_miniature")).is_false()
	view.open(sdk, locale, SDK.ActorId.new("enemy"), "", {})
	view.browser.get_node("Results/Rows").get_child(1).pressed.emit()
	host.fail_commit = true
	view.get_node("Actions/Apply").pressed.emit()
	await get_tree().process_frame
	assert_bool(view.visible).is_true()
	assert_bool(host.actors.enemy.data.has("preferred_miniature")).is_false()
	host.fail_commit = false
	view.get_node("Actions/Apply").pressed.emit()
	await get_tree().process_frame
	assert_dict(sdk.actors.read(SDK.ActorId.new("enemy")).actor.data.preferred_miniature).is_equal(WARDEN)
	assert_bool(view.visible).is_false()

func test_application_defaults_and_explicit_choices() -> void:
	var definitions = preload(ROOT + "logic/creature_definition.gd")
	for entry in [["bent-scum", "bandit"], ["seth-goblin", "goblin"], ["zukuma-berserker", "barbarian"]]:
		assert_str(definitions.new().effective_miniature({"definition_id": entry[0]}).local_id).is_equal(entry[1])
	assert_str(definitions.new().effective_miniature({"definition_id": "arbint-troll"}).local_id).is_equal("default-miniature")
	assert_str(definitions.new().effective_miniature({}).local_id).is_equal("default-miniature")
	assert_dict(definitions.new().effective_miniature({"definition_id": "seth-goblin", "preferred_miniature": WARDEN})).is_equal(WARDEN)
	assert_dict(definitions.new().effective_miniature({"preferred_miniature": {"package_id": "missing", "local_id": "saved"}})).is_equal({"package_id": "missing", "local_id": "saved"})
