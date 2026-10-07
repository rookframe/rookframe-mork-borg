extends GdUnitTestSuite

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ACTIONS = preload(ROOT + "logic/creature_actions.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/melee_sdk_boundary.gd")

func test_custom_loot_accepts_explicit_single_die_damage() -> void:
	var host := BOUNDARY.new()
	var system := SYSTEM.new()
	add_child(auto_free(system))
	host.handler = system
	host.actors.hero.data = load(ROOT + "content/seth-goblin.tres").create_data({})
	var actions := ACTIONS.new(SDK.new(host), SDK.ActorId.new("hero"))
	var result := await actions.add_custom({"name": "Review knife", "kind": "Weapon", "quantity": "1", "uses": "0", "damage": "1d4", "range_feet": "0", "armor_tier": "0", "reduction": "", "rules": ""})
	assert_bool(result.ok).override_failure_message("A custom item with 1d4 damage must save: " + result.message).is_true()
	if result.ok:
		assert_str(result.actor.data.inventory[-1].damage).is_equal("d4")
		var item_id: String = result.actor.data.inventory[-1].inventory_id
		for formula in [" d6 ", "1D6", " 1d6 "]:
			result = await actions.change_item(item_id, "damage", formula)
			assert_bool(result.ok).is_true()
			assert_str(result.actor.data.inventory[-1].damage).is_equal("d6")
		result = await actions.change_item(item_id, "reduction", "1d4")
		assert_bool(result.ok).is_true()
		assert_str(result.actor.data.inventory[-1].reduction).is_equal("d4")
		var saved: Dictionary = host.actors.hero.data.duplicate(true)
		result = await actions.change_item(item_id, "damage", "1d99")
		assert_bool(result.ok).is_false()
		assert_str(actions.invalid_field).is_equal("damage")
		assert_str(result.message).contains("d4+1")
		assert_dict(host.actors.hero.data).is_equal(saved)

func test_custom_form_saves_typed_damage_and_keeps_creature_capabilities() -> void:
	var host = load("res://tests/creature_appearance_boundary.gd").new()
	host.handler = auto_free(SYSTEM.new())
	add_child(host.handler)
	host.actors.hero.data = load(ROOT + "content/seth-goblin.tres").create_data({})
	host.actors.hero.access_level = "Owner"
	var attacks: Array = host.actors.hero.data.attacks.duplicate(true)
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(1920, 1080)
	add_child(viewport)
	var surface = load(ROOT + "ui/creature_surface.tscn").instantiate()
	surface.set_meta("rookframe_sdk", host)
	viewport.add_child(surface)
	surface._rookframe_open_actor("hero")
	surface._catalogue()
	for frame in range(6):
		await get_tree().process_frame
	assert_bool(surface._catalogue_empty.visible).override_failure_message("An empty search must show the equipment catalogue.").is_false()
	surface._filter_catalogue("no-such-equipment")
	assert_bool(surface._catalogue_empty.visible).is_true()
	surface._filter_catalogue("")
	assert_bool(surface._catalogue_buttons[0].visible).is_true()
	surface._custom()
	for frame in range(6):
		await get_tree().process_frame
	var fields: Dictionary = {"name": "Review knife", "kind": "Weapon", "damage": "1d4"}
	for field in surface._fields:
		if fields.has(field._field):
			var editor: LineEdit = field.get_node("Value/Editor")
			editor.text = fields[field._field]
			editor.text_changed.emit(editor.text)
	await surface._add_custom()
	assert_str(surface._detail).is_empty()
	assert_str(host.actors.hero.data.inventory[-1].name).is_equal("Review knife")
	assert_str(host.actors.hero.data.inventory[-1].damage).is_equal("d4")
	assert_array(host.actors.hero.data.attacks).is_equal(attacks)
	var items := ACTIONS.new(SDK.new(host), SDK.ActorId.new("hero")).inventory(host.actors.hero.data)
	assert_str(str(items[-1].get("rules", ""))).override_failure_message("A custom item without rules must not inherit another catalogue entry's rules.").is_empty()
