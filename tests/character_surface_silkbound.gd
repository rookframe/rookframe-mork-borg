extends GdUnitTestSuite
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const BOUNDARY = preload("res://tests/miniature_boundary.gd")
const SYSTEM = preload(ROOT + "logic/implementation.gd")
const CHAPTER := ^"Margin/Layout/Body/Chapter"

func _open(canvas: Vector2i) -> Dictionary:
	var host := BOUNDARY.new()
	host.game_master = true
	host.actors.hero.data.merge({"name":"Graveworm", "class_id":"occult-herbmaster", "class_title":"Occult Herbmaster", "class_rules":["Prepare decoctions and recognise the herbs of Sarkash."], "hit_points":7, "maximum_hit_points":9, "power_uses":2, "power_uses_total":3, "omens":2, "silver":34, "abilities":{"Strength":{"modifier":-1},"Agility":{"modifier":0},"Presence":{"modifier":1},"Toughness":{"modifier":2}},"traits":[],"inventory":[{"inventory_id":"sword","source_item_id":"sword","name":"Sword","kind":"Weapon","damage":"d6","attack_ability":"Strength","range_feet":5,"equipped":true,"quantity":1},{"inventory_id":"bow","source_item_id":"shortbow","name":"Shortbow","kind":"Weapon","damage":"d6","attack_ability":"Presence","range_feet":60,"equipped":true,"quantity":1},{"inventory_id":"shield","name":"Shield","kind":"Shield","reduction":"-1","equipped":true,"quantity":1}]}, true)
	host.handler = auto_free(SYSTEM.new())
	host.handler.sdk = SDK.new(host)
	add_child(host.handler)
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = canvas
	viewport.gui_embed_subwindows = true
	add_child(viewport)
	var sheet = load(ROOT + "ui/character_surface.tscn").instantiate()
	sheet.sdk = SDK.new(host)
	viewport.add_child(sheet)
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.opened(SDK.ActorId.new("hero"))
	return {"host":host,"sheet":sheet,"viewport":viewport}

func _settle() -> void:
	for frame in 24:
		await get_tree().process_frame

func test_chapters_and_details_stay_inside_reference_canvas(width: int, height: int, _test_parameters := [[1920,1080],[1024,768],[844,390]]) -> void:
	var fixture := _open(Vector2i(width,height))
	var sheet: Control = fixture.sheet
	await _settle()
	for chapter in 5:
		sheet._chapter(chapter)
		await _settle()
		var tabs: Control = sheet.get_node(CHAPTER).get_node(^"Tabs")
		assert_bool(sheet.get_global_rect().encloses(tabs.get_global_rect())).is_true()
		var count := 0
		for tab: Control in tabs.get_children():
			if tab.visible:
				count += 1
				assert_bool(tab.size.x >= 44 and tab.size.y >= 44).is_true()
		assert_int(count).is_equal(5)
		_assert_buttons_bounded(sheet, sheet.get_global_rect())
		if chapter < 3:
			var collection: Control = sheet.get_node(CHAPTER).get_node(^"Page/Content/Collections/Primary")
			assert_bool(sheet.get_global_rect().encloses(collection.get_global_rect())).is_true()
	sheet._chapter(0)
	sheet._open_detail("ability:Strength")
	await _settle()
	_assert_buttons_bounded(sheet, sheet.get_global_rect())
	sheet._back()
	await _settle()
	assert_str(sheet._detail).is_empty()

func test_reading_controls_have_padding_and_visible_window_actions(width: int, height: int, _test_parameters := [[1920,1080],[1024,768],[844,390]]) -> void:
	var fixture := _open(Vector2i(width,height))
	var sheet = fixture.sheet
	await _settle()
	assert_bool((sheet._core_ui.get_node("PhoneHeader/PhoneClose") if width <= 900 else sheet._header_close).is_visible_in_tree()).is_true()
	assert_bool((sheet._core_phone_edit if width <= 900 else sheet._header_edit).is_visible_in_tree()).is_true()
	assert_bool(sheet._chapter_tab_appearance.is_visible_in_tree()).is_true()
	for button in [sheet._core_hit_points, sheet._core_power_uses]:
		var copy: Control = button.get_node("Inset/Copy")
		assert_bool(button.get_global_rect().grow(-4).encloses(copy.get_global_rect())).override_failure_message("Resource content must have padding within its button: " + str(copy.get_global_rect()) + " / " + str(button.get_global_rect())).is_true()
		assert_float(button.get_theme_stylebox("normal").content_margin_left).is_greater_equal(6.0)
	for path in ["StrengthRow/Strength", "AgilityRow/Agility", "PresenceRow/Presence", "ToughnessRow/Toughness"]:
		var ability: Button = sheet._core_ui.get_node("Abilities/" + path)
		assert_float(ability.get_theme_stylebox("normal").content_margin_left).is_greater_equal(6.0)

func _assert_buttons_bounded(node: Node, bounds: Rect2) -> void:
	if node is Button and node.is_visible_in_tree():
		assert_bool(bounds.grow(1).encloses(node.get_global_rect())).override_failure_message(str(node.get_path()) + " extends beyond the reference canvas: " + str(node.get_global_rect())).is_true()
	for child in node.get_children():
		_assert_buttons_bounded(child,bounds)

func test_ready_weapon_summary_uses_selected_weapons_attack_ability() -> void:
	var fixture := _open(Vector2i(1920,1080))
	await _settle()
	var sheet = fixture.sheet
	var value: Label = sheet.get_node(^"Margin/Layout/Body/Core/WeaponActions/Attack/Summary/Test/Value")
	assert_str(value.text).is_equal("−1")
	sheet._weapon_selected(1)
	assert_str(value.text).is_equal("+1")
	assert_str(sheet._nav.weapon).is_equal("bow")
	await _settle()

func test_window_reparent_preserves_sheet_layout() -> void:
	var fixture := _open(Vector2i(1920,1080))
	await _settle()
	var sheet: Control = fixture.sheet
	var window: Window = auto_free(Window.new())
	window.size = Vector2i(1920,1080)
	fixture.viewport.add_child(window)
	sheet.reparent(window)
	await _settle()
	assert_vector(sheet.size).is_equal(Vector2(1920,1080))
	assert_str(sheet._actor.data.name).is_equal("Graveworm")
	sheet.reparent(fixture.viewport)
	await _settle()

func test_inventory_details_toggle_and_read_only_access_are_separate() -> void:
	var fixture := _open(Vector2i(1920,1080))
	var sheet = fixture.sheet
	var host = fixture.host
	sheet._chapter(2)
	await _settle()
	sheet._open_detail("item:sword")
	await _settle()
	assert_bool(host.actors.hero.data.inventory[0].equipped).is_true()
	sheet._back()
	await _settle()
	await sheet._inventory_action("item:sword")
	await _settle()
	assert_bool(host.actors.hero.data.inventory[0].equipped).is_false()
	assert_int(host.actors.hero.data.inventory[0].quantity).is_equal(1)
	assert_str(sheet._detail).is_empty()
	host.actors.hero.access_level = "Viewer"
	host.WorldChanged.emit()
	await _settle()
	await sheet._inventory_action("item:sword")
	assert_bool(host.actors.hero.data.inventory[0].equipped).is_false()
	var rows: Dictionary = sheet._projection.collections(sheet._actor.data,sheet._items,2,"hero",sheet.sdk,0,false)
	assert_bool(rows.primary[0].action_disabled).is_true()
	sheet._open_detail("item:sword")
	await _settle()
	assert_str(sheet._detail).is_equal("item:sword")

func test_journal_keeps_saved_words_for_the_current_visit(width: int, height: int, _test_parameters := [[1920,1080],[1024,768],[844,390]]) -> void:
	var fixture := _open(Vector2i(width,height))
	var sheet = fixture.sheet
	await _settle()
	sheet._chapter(3)
	sheet._open_detail("journal:notes")
	await _settle()
	assert_int(sheet._detail_tab).is_equal(1)
	if width > 900:
		assert_vector(sheet.get_node("EntryDialog").size).is_equal(Vector2i(640,610))
	_assert_buttons_bounded(sheet, sheet.get_global_rect())
	assert_bool(sheet._detail_ui.get_node("Body/DetailPages/Area/DetailContent/FullTitle").visible).is_false()
	await sheet._primary_action()
	await _settle()
	assert_int(sheet._detail_tab).is_equal(2)
	if width > 900:
		assert_vector(sheet.get_node("EntryDialog").size).is_equal(Vector2i(640,mini(790,height-70)))
	_assert_buttons_bounded(sheet, sheet.get_global_rect())
	assert_bool(sheet._detail_ui.get_node("TabsFrame").visible).is_false()
	sheet._detail_ui.journal_draft = "The forest remembers."
	await sheet._primary_action()
	await _settle()
	sheet._open_detail("journal:story")
	await _settle()
	sheet._open_detail("journal:notes")
	await _settle()
	assert_str(sheet._detail_ui.journal_draft).is_equal("The forest remembers.")
	assert_str(sheet._nav.notes).is_equal("The forest remembers.")
	assert_bool(fixture.host.actors.hero.data.has("notes")).is_false()

func test_cancel_note_editing_returns_to_saved_reading_page() -> void:
	var fixture := _open(Vector2i(1920,1080))
	var sheet = fixture.sheet
	await _settle()
	sheet._nav["notes"] = "Saved words."
	sheet._open_detail("journal:notes")
	await _settle()
	await sheet._primary_action()
	await _settle()
	sheet._detail_ui.journal_draft = "Discarded words."
	sheet._back()
	await _settle()
	assert_str(sheet._nav.notes).is_equal("Saved words.")
	assert_str(sheet._detail_ui.journal_draft).is_equal("Saved words.")
	assert_str(sheet._detail).is_equal("journal:notes")
	assert_int(sheet._detail_tab).is_equal(1)

func test_header_edit_and_appearance_actions_are_reachable() -> void:
	var fixture := _open(Vector2i(1920,1080))
	var sheet = fixture.sheet
	await _settle()
	sheet._header_edit.pressed.emit()
	await _settle()
	assert_bool(sheet._draft.active).is_true()
	assert_bool(sheet._header_save_sheet.is_visible_in_tree()).is_true()
	sheet._header_cancel_sheet.pressed.emit()
	await _settle()
	assert_bool(sheet._draft.active).is_false()
	sheet._chapter_tab_appearance.pressed.emit()
	await _settle()
	assert_bool(sheet._appearance_ui.is_visible_in_tree()).is_true()
	assert_bool(sheet._appearance_ui.get_node("Columns/PortraitPanel/Inset/Content/PortraitButtons/ChangePortrait").disabled).is_false()
	sheet._appearance_change_miniature.pressed.emit()
	await _settle()
	assert_bool(sheet.get_node("Margin/Layout/Picker").visible).is_true()
	sheet._picker_closed(false)
	await _settle()
	assert_bool(sheet._appearance_change_miniature.has_focus()).is_true()

func test_note_footer_has_compact_primary_action_and_icon_back() -> void:
	var fixture := _open(Vector2i(1920,1080))
	var sheet = fixture.sheet
	await _settle()
	sheet._open_detail("journal:notes")
	await _settle()
	assert_bool(sheet._detail_back.get_node("Copy/Caption").visible).is_false()
	assert_float(sheet._primary_button.size.x).is_less(250.0)
	assert_float(sheet._primary_button.get_global_rect().end.x).is_greater(sheet._detail_ui.get_global_rect().get_center().x)
	assert_float(sheet._detail_ui.get_node("FooterFrame").size.y).is_less_equal(70.0)

func test_sheet_actions_use_icons_and_appearance_controls_have_consistent_spacing() -> void:
	var fixture := _open(Vector2i(1920,1080))
	var sheet = fixture.sheet
	await _settle()
	assert_str(sheet._header_edit.text).is_empty()
	assert_str(sheet._header_edit.icon.resource_path).is_equal("res://rookframe/ui/icons/edit.svg")
	assert_str(sheet._header_close.text).is_empty()
	assert_str(sheet._header_close.icon.resource_path).is_equal("res://rookframe/ui/icons/close.svg")
	fixture.host.actors.hero.data.inventory.append({"inventory_id":"food", "source_item_id":"dried-food", "name":"Dried food", "kind":"Equipment", "quantity":3})
	sheet.opened(SDK.ActorId.new("hero"))
	sheet._chapter(2)
	await _settle()
	var records: Dictionary = sheet._projection.collections(sheet._actor.data,sheet._items,2,"hero",sheet.sdk,0,true)
	var used := false
	for entry in records.primary:
		if entry.has("action"):
			assert_str(str(entry.get("action_text", ""))).is_empty()
			assert_object(entry.action_icon).is_not_null()
			if entry.id == "item:food":
				used = true
				assert_str(entry.action).is_equal("Use Dried food")
	assert_bool(used).is_true()
	sheet._chapter(4)
	await _settle()
	var appearance = sheet._appearance_ui
	for panel in ["Portrait", "Miniature"]:
		var content: Control = appearance.get_node("Columns/" + panel + "Panel/Inset/Content")
		var buttons = content.get_node(panel + "Buttons")
		var choose: Button = buttons.get_child(0)
		assert_int(buttons.get_theme_constant("h_separation")).is_equal(12)
		assert_str(buttons.get_child(1).text).is_equal("Reset")
		assert_object(choose.icon).is_null()
		assert_str(choose.text).is_not_empty()
		assert_bool(choose.get_theme_color("font_focus_color") == choose.get_theme_color("font_color")).is_true()
		assert_float(content.get_node("HeadingGap").size.y).is_greater_equal(8)
		var preview: Control = content.get_node("PortraitPreview" if panel == "Portrait" else "EmptyPreview")
		var group: Rect2 = choose.get_global_rect()
		if buttons.get_child(1).visible:
			group = group.merge(buttons.get_child(1).get_global_rect())
		assert_float(absf(group.get_center().x - preview.get_global_rect().get_center().x)).is_less_equal(1.0)
		assert_float(appearance.get_node("Columns/" + panel + "Panel").get_theme_stylebox("panel").bg_color.a).is_equal(0.0)
	assert_bool(sheet._chapter_ui.get_node(^"Page/Content/AppearanceStatus").visible).is_false()

func test_single_page_details_hide_pager_and_long_notes_keep_navigation() -> void:
	var fixture := _open(Vector2i(1920,1080))
	var sheet = fixture.sheet
	await _settle()
	sheet._open_detail("journal:notes")
	await _settle()
	var details = sheet._detail_ui
	assert_bool(details.get_node("Body/DetailPages").get_pager().is_visible_in_tree()).is_false()
	assert_bool(details.get_node("Body/NoteEditor").get_pager().is_visible_in_tree()).is_false()
	await sheet._primary_action()
	await _settle()
	assert_bool(details.get_node("Body/DetailPages").get_pager().is_visible_in_tree()).is_false()
	assert_bool(details.get_node("Body/NoteEditor").get_pager().is_visible_in_tree()).is_false()
	var editor = details.get_node("Body/NoteEditor")
	editor.value = "The forest remembers every footstep.\n".repeat(100)
	await _settle()
	assert_bool(editor.get_pager().is_visible_in_tree()).is_true()
	var pager = editor.get_pager()
	assert_bool(pager.get_node("Next").disabled).is_false()
	pager.get_node("Next").pressed.emit()
	await _settle()
	assert_bool(pager.get_node("Previous").disabled).is_false()
	sheet._back()
	await _settle()
	assert_bool(details.get_node("Body/DetailPages").get_pager().is_visible_in_tree()).is_false()
	assert_bool(details.get_node("Body/NoteEditor").get_pager().is_visible_in_tree()).is_false()

func test_hover_hints_cover_core_and_chapters_and_follow_weapon_selection() -> void:
	var fixture := _open(Vector2i(1920,1080))
	fixture.host.actors.hero.data.inventory.append({"inventory_id":"armor", "name":"Light armor", "kind":"Armor", "reduction":"-d2", "equipped":true,"quantity":1})
	var sheet = fixture.sheet
	sheet.opened(SDK.ActorId.new("hero"))
	await _settle()
	var core = sheet._core_ui
	var strength = core.get_node("Abilities/StrengthRow/Strength")
	assert_str(strength.tooltip_text).contains("Physical force and melee attacks.")
	var armor = core.get_node("ProtectionItems").get_child(1)
	var tooltip = auto_free(armor._make_custom_tooltip(armor.tooltip_text))
	assert_str(tooltip.get_node("Title").text).is_equal("Light armor · Protection")
	assert_str(tooltip.get_node("Summary").text).is_equal("Armor is passive protection. Roll the amount to subtract from damage.")
	assert_str(core.get_node("Dodge").tooltip_text).contains("Test Agility")
	var attack = core.get_node("WeaponActions/Attack")
	assert_str(attack.tooltip_text).contains("Melee attack using Strength.")
	sheet._weapon_selected(1)
	assert_str(attack.tooltip_text).contains("Shortbow · Shoot")
	assert_str(attack.tooltip_text).contains("Ranged attack using Presence.")
	for chapter in 4:
		sheet._chapter(chapter)
		await _settle()
		for group in ["Primary", "Secondary/Content/Resources"]:
			var rows = sheet.get_node(CHAPTER).get_node("Page/Content/Collections/" + group + "/Content/Area/Rows")
			for row in rows.get_children():
				assert_str(row.get_node("Details").tooltip_text).is_not_empty()
