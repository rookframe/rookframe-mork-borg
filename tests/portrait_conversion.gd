extends GdUnitTestSuite
## Conversion risks losing existing saved images or leaving oversized inline records.
## This SDK seam proves synchronous copied-data conversion and failure signaling;
## actual atomic persistence and startup refusal belong to host acceptance.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const BOUNDARY = preload("res://tests/creature_appearance_boundary.gd")

func _image() -> PackedByteArray:
	var image := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.DARK_RED)
	return image.save_png_to_buffer()

func test_saved_actor_and_world_callbacks_preserve_gameplay_and_source_copies() -> void:
	var host := BOUNDARY.new()
	var image := _image()
	var system = auto_free(SYSTEM.new())
	system.sdk = SDK.new(host)
	var first_path := ""
	for schema in ["mork-borg-character/v1", "mork-borg-adversary/v1"]:
		var original := {"schema": schema, "name": "Accepted identity", "hit_points": -3, "portrait": image, "portrait_revision": 9, "inventory": [{"inventory_id": "7", "name": "Saved loot", "quantity": 2}]}
		var expected := original.duplicate(true)
		# The real synchronous public callback returns a completed replacement.
		var converted: Dictionary = system._rookframe_migrate_actor_data(original)
		var path: String = converted.portrait
		assert_str(path).starts_with("portraits/")
		assert_bool(host.retained_portraits[path] == image).is_true()
		expected.portrait = path
		assert_dict(converted).is_equal(expected)
		assert_bool(original.portrait == image).is_true()
		first_path = path
		var calls := host.retention_calls
		assert_dict(system._rookframe_migrate_actor_data(converted)).is_equal(expected)
		assert_int(host.retention_calls).is_equal(calls)
	var original_world := {"unrelated": "retained", "creature_portraits": {"seth-goblin": image, "lich-necromancer": "portraits/already-retained.png"}, "creature_portrait_revisions": {"seth-goblin": 9}}
	var converted_world: Dictionary = system._rookframe_migrate_world_data(original_world)
	assert_str(converted_world.creature_portraits["seth-goblin"]).is_equal(first_path)
	assert_str(converted_world.creature_portraits["lich-necromancer"]).is_equal("portraits/already-retained.png")
	assert_str(converted_world.unrelated).is_equal("retained")
	assert_dict(converted_world.creature_portrait_revisions).is_equal(original_world.creature_portrait_revisions)
	assert_bool(original_world.creature_portraits["seth-goblin"] == image).is_true()

func test_retention_failure_signals_startup_error_and_preserves_inline_value_for_retry() -> void:
	var host := BOUNDARY.new()
	var image := _image()
	var system = auto_free(SYSTEM.new())
	system.sdk = SDK.new(host)
	var original := {"schema": "mork-borg-character/v1", "hit_points": 7, "portrait": image}
	var returned: Array = []
	host.fail_retention = true
	await assert_error(func(): returned.append(system._rookframe_migrate_actor_data(original))).is_push_error("Saved portrait conversion failed: Portrait retention failed")
	assert_dict(returned[0]).is_equal(original)
	assert_bool(original.portrait == image).is_true()
	host.fail_retention = false
	var converted: Dictionary = system._rookframe_migrate_actor_data(original)
	assert_str(converted.portrait).starts_with("portraits/")
	assert_int(converted.hit_points).is_equal(7)

func test_failed_world_conversion_returns_original_defaults_and_empty_portraits_reset_without_upload() -> void:
	var host := BOUNDARY.new()
	var image := _image()
	var system = auto_free(SYSTEM.new())
	system.sdk = SDK.new(host)
	var original := {"unrelated": "retained", "creature_portraits": {"seth-goblin": image}}
	var returned: Array = []
	host.fail_retention = true
	await assert_error(func(): returned.append(system._rookframe_migrate_world_data(original))).is_push_error("Saved portrait conversion failed: Portrait retention failed")
	assert_dict(returned[0]).is_equal(original)
	host.fail_retention = false
	var converted: Dictionary = system._rookframe_migrate_world_data(original)
	assert_str(converted.creature_portraits["seth-goblin"]).starts_with("portraits/")
	var calls := host.retention_calls
	converted = system._rookframe_migrate_actor_data({"schema": "mork-borg-adversary/v1", "portrait": PackedByteArray(), "hit_points": 2})
	assert_bool(converted.has("portrait")).is_false()
	assert_int(converted.hit_points).is_equal(2)
	assert_int(host.retention_calls).is_equal(calls)
