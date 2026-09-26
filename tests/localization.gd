extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const LOCALE = preload(ROOT + "ui/localization.gd")
const BOUNDARY = preload("res://tests/localization_boundary.gd")

func _locale(language: String):
	var boundary := BOUNDARY.new()
	boundary.language = language
	var locale := LOCALE.new()
	locale.bind(SDK.new(boundary))
	return locale

func test_russian_creation_uses_display_labels_without_changing_draft() -> void:
	var view = auto_free(load(ROOT + "ui/character_creation_view.tscn").instantiate())
	view.localize(_locale("ru_RU"))
	add_child(view)
	var profile: Dictionary = load(ROOT + "logic/creation_classes.gd").new().profile("fanged-deserter")
	var draft := {"class_id": "fanged-deserter", "class_title": profile.title, "class_profile": profile, "class_rules": profile.rules, "name": "Strength", "description": "My character", "origin": profile.origins[0], "inventory": []}
	var before := draft.duplicate(true)
	view.present_creation("create-abilities", draft, true)
	assert_str(view.get_node("Main/Content/Abilities/Agility/Row/Identity/Title").text).is_equal("Ловкость")
	view.present_creation("create-review", draft, false)
	assert_str(view.get_node("Main/Content/Review/Name").text).is_equal("Strength")
	assert_str(view.get_node("Main/Content/Review/Description").text).contains("Клыкастый дезертир")
	assert_str(view.get_node("Main/Content/Review/Description").text).contains("My character")
	assert_dict(draft).is_equal(before)

func test_dynamic_inventory_and_search_preserve_source_ids() -> void:
	var view = auto_free(load(ROOT + "ui/equipment_catalogue.tscn").instantiate())
	view.localize(_locale("ru"))
	add_child(view)
	view.configure({}, [])
	view._filter("меч")
	var sword: Control
	for row in view._rows:
		if str(row.item.source_item_id) == "sword":
			sword = row
	assert_object(sword).is_not_null()
	assert_bool(sword.visible).is_true()
	assert_str(sword.get_node("Copy/Title").text).is_equal("Меч")
	assert_str(sword.item.name).is_equal("Sword")
	var custom = auto_free(load(ROOT + "ui/inventory_row.tscn").instantiate())
	custom.localize(_locale("ru"))
	add_child(custom)
	custom.configure({"name": "Strength", "custom": true, "quantity": 2, "inventory_id": "custom"})
	assert_str(custom.get_node("Copy/Title").text).is_equal("Strength")
	assert_str(custom.get_node("Copy/Details").text).contains("Количество: 2")

func test_editable_values_and_fallback() -> void:
	for language in ["ru", "en", "de"]:
		var locale = _locale(language)
		var view = auto_free(load(ROOT + "ui/sheet_field.tscn").instantiate())
		view.localize(locale)
		add_child(view)
		view.configure("name", "Name", "Strength")
		assert_str(view.current_value()).is_equal("Strength")
		assert_str(view.get_node("Field").label_text).is_equal("Имя" if language == "ru" else "Name")
		assert_str(locale.text("A player's unknown phrase")).is_equal("A player's unknown phrase")
		view.get_node("Field").value = "Unsaved name"
		view.refresh_value("Strength")
		assert_str(view.current_value()).is_equal("Unsaved name")

func test_edit_labels_translate_without_rewriting_named_content() -> void:
	var view = auto_free(load(ROOT + "ui/character_sheet_edit.tscn").instantiate())
	view.localize(_locale("ru"))
	add_child(view)
	var data := {"traits": [{"id": "custom", "name": "My trait", "rules": "My rules"}], "companion_sheets": [{"name": "My companion", "rules": "Their rules"}]}
	view.configure(data, [])
	var found := false
	for field in view._fields:
		if field.field == "trait:0:name":
			assert_str(field.get_node("Field").label_text).is_equal("Черта: имя")
			assert_str(field.current_value()).is_equal("My trait")
		if field.field == "trait:0:rules":
			assert_str(field.get_node("Multiline").label_text).is_equal("My trait: правила")
			assert_str(field.current_value()).is_equal("My rules")
			found = true
	assert_bool(found).is_true()

func test_catalog_covers_all_authored_rule_content_and_preserves_formats() -> void:
	var english: Translation = load(ROOT + "i18n/en.tres")
	var russian: Translation = load(ROOT + "i18n/ru.tres")
	assert_int(russian.get_message_count()).is_equal(english.get_message_count())
	var formats := RegEx.new()
	formats.compile("%[-+0-9.]*[dsf]")
	for message in english.get_message_list():
		var translated := str(russian.get_message(message))
		assert_str(translated).is_not_empty()
		var source_formats: Array[String] = []
		var translated_formats: Array[String] = []
		for match in formats.search_all(message):
			source_formats.append(match.get_string())
		for match in formats.search_all(translated):
			translated_formats.append(match.get_string())
		assert_array(translated_formats).is_equal(source_formats)
	_assert_content(load(ROOT + "logic/creation_classes.gd").PROFILES, russian)
	_assert_content(load(ROOT + "logic/starting_scrolls.gd").TABLES, russian)
	_assert_content(load(ROOT + "logic/creature_definition.gd").CORE_DEFINITIONS, russian)
	_assert_content(load(ROOT + "logic/equipment.gd").new().entries(), russian)

func _assert_content(value: Variant, catalog: Translation, key: String = "") -> void:
	if value is Dictionary:
		for field in value:
			_assert_content(value[field], catalog, str(field))
	elif value is Array:
		for entry in value:
			_assert_content(entry, catalog, key)
	elif value is String and key in ["name", "title", "rules", "origins", "handling"] and not value.is_empty():
		assert_str(str(catalog.get_message(value))).override_failure_message("Missing Russian content: " + value).is_not_empty()

func test_long_russian_live_names_fit_the_phone_content_width() -> void:
	var window = auto_free(load(ROOT + "ui/window.tscn").instantiate())
	window.i18n = _locale("ru")
	var list: VBoxContainer = window.get_node("Layout/Body/Content/LiveList")
	window._live_list = list
	window._actors.append(SDK.Actor.new({"id": "fixture", "data": {"name": "Персонаж с очень длинным именем"}, "access_level": "Owner", "public_label": "Незнакомец с очень длинным именем"}))
	list.owner = null
	list.get_parent().remove_child(list)
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(375, 369)
	add_child(viewport)
	viewport.add_child(auto_free(list))
	window._render_live_actors()
	list.size = Vector2(351, 100)
	await get_tree().process_frame
	await get_tree().process_frame
	var row: Button = list.get_child(0)
	assert_bool(list.get_combined_minimum_size().x <= 351).is_true()
	assert_bool(row.size.x <= 351).is_true()
	assert_bool(row.size.y >= 44).is_true()
	assert_str(row.tooltip_text).contains("Персонаж с очень длинным именем")
	assert_str(row.tooltip_text).contains("Незнакомец с очень длинным именем")
	assert_str(row.accessibility_name).is_equal(row.tooltip_text)

func test_russian_cast_confirmation_wraps_inside_phone_width() -> void:
	var panel = auto_free(load(ROOT + "ui/powers_panel.tscn").instantiate())
	panel.localize(_locale("ru"))
	var eligible: CheckBox = panel.get_node("Cast/Options/Eligible")
	eligible.owner = null
	eligible.get_parent().remove_child(eligible)
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(375, 369)
	add_child(viewport)
	viewport.add_child(auto_free(eligible))
	eligible.size = Vector2(351, 44)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(eligible.get_combined_minimum_size().x <= 351).is_true()
	assert_bool(eligible.size.x <= 351).is_true()
	assert_bool(eligible.size.y >= 44).is_true()
	assert_str(eligible.text).is_equal(_locale("ru").text("Not dizzy; requirements met"))
