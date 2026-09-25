extends GdUnitTestSuite

# Deterministic rule cases use the real authored creator and generated public
# SDK. Only the host's randomness/storage boundary is substituted here; the
# application Package Services suite owns persistence, authority and replication.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const CREATOR = preload(ROOT + "ui/character_creator.tscn")
const BOUNDARY = preload("res://tests/creation_sdk_boundary.gd")
var stage := 0
var stages: Array[int] = []
var primary := ""
var disabled := false

func test_required_pack_choice() -> void:
	var host = _host_for("occult-herbmaster", 1)
	host.outcomes["Equipment pack"] = [[6]]
	var creator = _creator_for(host, "occult-herbmaster")
	for iteration in range(180):
		await get_tree().process_frame
		if stage == 4 and not host.requests.is_empty() and str(host.requests[-1].name).begins_with("Armor"):
			await get_tree().process_frame
			break
		if not disabled:
			creator.primary()
	creator.primary()
	_check(stage == 4 and host.actors.is_empty(), "Equipment waits for the required source pack choice.")
	creator.get_node(^"View/Aside/Context/Content/Pack").pressed.emit()
	await _finish(creator)
	_check(host.actors.size() == 1 and host.actors[0].data.pack == "Nothing", "Nothing is an explicit legal pack choice.")
	creator.free()


func test_remaining_class_lifetimes() -> void:
	for case in [["wretched-royalty", "Second gift"], ["wretched-royalty", "Armor"], ["heretical-priest", "Class feature"], ["occult-herbmaster", "Second decoction"], ["occult-herbmaster", "Decoction doses"]]:
		for restart in [false, true]:
			var host = _host_for(case[0], 1)
			host.pending_roll = case[1]
			var creator = _creator_for(host, case[0])
			for iteration in range(160):
				await get_tree().process_frame
				if not host.pending_result.is_empty():
					break
				if not disabled:
					creator.primary()
			_check(not host.pending_result.is_empty(), "The class Roll reaches the pending public SDK boundary.")
			var rolls_before: int = host.requests.size()
			if restart:
				creator.start_over()
			else:
				creator.discard()
			host.complete_pending()
			await get_tree().process_frame
			_check(host.actors.is_empty() and host.requests.size() == rolls_before, "Late class Rolls cannot create Actors or continue generation.")
			creator.discard()
			creator.free()


func test_correct_class_uses() -> void:
	for case in [["wretched-royalty", 6, "Horn of the Schleswig lords"], ["heretical-priest", 4, "The blasphemous Nechrubel Bible"], ["occult-herbmaster", 1, "Portable laboratory"]]:
		var host = _host_for(case[0], case[1])
		var creator = _creator_for(host, case[0])
		await _finish(creator)
		creator.free()
		var roll_count: int = host.requests.size()
		var sheet = load(ROOT + "ui/character_sheet.tscn").instantiate()
		add_child(auto_free(sheet))
		var miniatures: Array[SDK.ContentEntry] = []
		var choices: Array[Dictionary] = []
		sheet.set_character(SDK.Actor.new(host.actors[0]), "inventory", "character", miniatures, choices, SDK.new(host))
		await get_tree().process_frame
		await get_tree().process_frame
		var found := false
		for row in sheet.find_children("*", "HBoxContainer", true, false):
			if row.get_script() != load(ROOT + "ui/inventory_row.gd"):
				continue
			if row.item.name == case[2]:
				row.get_node(^"Actions/Edit").pressed.emit()
				found = true
				break
		await get_tree().process_frame
		await get_tree().process_frame
		_check(found, "Completed class resource has an item-local correction entry.")
		for field in sheet.find_children("*", "VBoxContainer", true, false):
			if field.get_script() == load(ROOT + "ui/sheet_field.gd") and field.field == "uses":
				field.get_node(^"Field").set("value", "0")
				field.get_node(^"Actions/Save").pressed.emit()
				break
		await get_tree().process_frame
		var stored: SDK.ActorResult = SDK.new(host).actors.read(SDK.ActorId.new("character"))
		_check(stored.ok and stored.actor.data.inventory.any(func(item): return item.get("name", "") == case[2] and item.get("uses", -1) == 0), "Ordinary sheet save retains corrected remaining uses through public Actor state.")
		_check(host.requests.size() == roll_count, "Corrections do not regenerate class mechanics.")
		sheet.free()


func test_remaining_class_tables() -> void:
	var priest := ["sacred-shepherds-crook", "stolen-mitre", "list-of-sins", "blasphemous-nechrubel-bible", "stones-taken-from-thel-emas-lost-temple", "wrong-jesus-crucifix"]
	var royalty := ["blade-of-your-ancestors", "poltroon-the-court-jester", "barbarister-the-incredible-horse", "hamfund-the-squire", "snake-skin-gift", "horn-of-the-schleswig-lords"]
	var decoctions := ["red-poison-decoction", "ezumiels-vapor", "southern-frog-stew", "elixir-vitalis", "spider-owl-soup", "fernors-philtre", "hyphos-enervating-snuff", "black-poison-decoction"]
	for class_id in ["wretched-royalty", "heretical-priest", "occult-herbmaster"]:
		for index in range(8 if class_id == "occult-herbmaster" else 6):
			var host = _host_for(class_id, index + 1)
			var creator = _creator_for(host, class_id)
			await _finish(creator)
			if _check(host.actors.size() == 1, "Class gifts never invent Creature combat profiles."):
				var data: Dictionary = host.actors[0].data
				var expected: String = (royalty if class_id == "wretched-royalty" else decoctions if class_id == "occult-herbmaster" else priest)[index]
				_check(data.traits[0].id == expected and not data.origin.is_empty(), "Every source class outcome survives confirmation.")
				if class_id == "wretched-royalty":
					_check(data.traits.size() == 2 and data.traits[1].id == expected, "Duplicate gifts are retained independently.")
					if index in [1, 2, 3]:
						_check(data.companion_sheets.size() == 2 and data.companion_sheets[0].source_item_id == expected, "Royalty companions remain descriptive sheet data.")
						await _descriptive_companions(host)
						if index == 3:
							_check(data.inventory.any(func(item): return item.get("source_item_id", "") == "eurekia" and item.get("damage", "") == "2d6" and item.get("uses", 0) == 1), "Hamfund retains the conditional cursed sword as special equipment.")
					else:
						_check(data.inventory.filter(func(item): return item.get("source_item_id", "") == expected).size() == 2, "Royalty equipment grants retain duplicates.")
				elif class_id == "heretical-priest":
					_check(data.inventory.any(func(item): return item.get("source_item_id", "") == expected), "Every Priest feature grants its actual equipment.")
					if index == 3:
						_check(data.inventory.any(func(item): return item.get("source_item_id", "") == expected and item.get("uses", 0) == 1), "The Bible starts with one daily use.")
				else:
					_check(data.decoction_rolls == [index + 1, index + 1], "Duplicate decoctions are retained without a reroll rule.")
					_check(data.inventory.filter(func(item): return item.get("kind", "") == "Decoction").size() == 2, "All eight decoction recipes are available.")
					if index < 3:
						_check(data.origin == "Calm isolation in the Sarkash dark.", "Herbmaster origin outcomes 1–3 share the printed origin.")
			_check(host.errors.is_empty(), "Every source outcome uses its prescribed physical dice: %s" % str(host.errors))
			creator.free()


func _descriptive_companions(host) -> void:
	var sheet = load(ROOT + "ui/character_sheet.tscn").instantiate()
	add_child(auto_free(sheet))
	var miniatures: Array[SDK.ContentEntry] = []
	var choices: Array[Dictionary] = []
	sheet.set_character(SDK.Actor.new(host.actors[0]), "character", "companions", miniatures, choices, SDK.new(host))
	await get_tree().process_frame
	await get_tree().process_frame
	var labels: Array = sheet.find_children("*", "Label", true, false)
	var expected_name: String = host.actors[0].data.companion_sheets[0].name
	_check(labels.any(func(label): return label.text.contains(expected_name)), "Descriptive companions are visible in the ordinary companion route.")
	_check(not sheet.find_children("*", "Button", true, false).any(func(button): return button.text.contains("Open sheet")), "Descriptive companions do not offer invented Creature sheets.")
	sheet.free()


func test_herbmaster() -> void:
	var host = _host_for("occult-herbmaster", 8)
	host.outcomes["Silver"] = [[2, 3]]
	host.outcomes["Toughness"] = [[6, 6, 6]]
	host.outcomes["Strength"] = [[1, 1, 1]]
	host.outcomes["First decoction"] = [[4]]
	host.outcomes["Second decoction"] = [[8]]
	host.outcomes["Decoction doses"] = [[3]]
	host.outcomes["Equipment second"] = [[4]]
	host.outcomes["Monkey count"] = [[2]]
	host.outcomes["Monkey 1 hit points"] = [[1]]
	host.outcomes["Monkey 2 hit points"] = [[4]]
	var creator = _creator_for(host, "occult-herbmaster")
	await _finish(creator)
	if _check(host.actors.size() == 3, "Herbmaster and two starting monkeys confirm as one bundle."):
		var data: Dictionary = host.actors[0].data
		_check(data.class_id == "occult-herbmaster" and data.abilities.Toughness.score == 20 and data.abilities.Strength.score == 1, "Herbmaster class and ability adjustments survive creation.")
		_check(data.hit_points == 7 and data.silver == 50 and data.omens == 2, "Herbmaster has Toughness+d6 HP, 2d6×10 silver and d2 Omens.")
		_check(data.origin.contains("Shadow King") and data.origin_roll == 8, "Herbmaster uses its d8 origin table.")
		_check(data.decoction_rolls == [4, 8] and data.traits.size() == 2, "Two d8 decoctions survive confirmation.")
		var labs: Array = data.inventory.filter(func(item): return item.get("source_item_id", "") == "portable-laboratory")
		_check(labs.size() == 1 and labs[0].uses == 3, "The portable laboratory holds one shared d4 dose pool, not d4 per recipe.")
		var recipes: Array = data.inventory.filter(func(item): return item.get("kind", "") == "Decoction")
		_check(recipes.size() == 2 and recipes[0].name == "Elixir vitalis" and recipes[1].name == "Black poison" and not recipes[0].has("uses"), "Named recipes use the shared pool without an invented allocation.")
		_check(host.actors[1].data.hit_points == 3 and host.actors[2].data.hit_points == 6, "Starting monkeys retain individual source HP rolls.")
	_check(host.requests.filter(func(term): return term.name == "Origin")[0].faces == 8, "Herbmaster origin requests a physical d8.")
	_check(host.errors.is_empty(), "Herbmaster does not request a class-feature d6: %s" % str(host.errors))
	creator.free()


func test_priest() -> void:
	var host = _host_for("heretical-priest", 6)
	host.outcomes["Silver"] = [[2, 3, 4]]
	host.outcomes["Presence"] = [[6, 6, 6]]
	host.outcomes["Strength"] = [[1, 1, 1]]
	host.outcomes["Hit points"] = [[8]]
	host.outcomes["Equipment second"] = [[2]]
	host.outcomes["Sacred scroll"] = [[7]]
	host.outcomes["Weapon"] = [[8]]
	host.outcomes["Armor"] = [[3]]
	var creator = _creator_for(host, "heretical-priest")
	await _finish(creator)
	if _check(host.actors.size() == 1, "Priest creates one Character."):
		var data: Dictionary = host.actors[0].data
		_check(data.class_id == "heretical-priest" and data.silver == 90 and data.hit_points == 8 and data.omens == 4, "Priest uses its class resource dice.")
		_check(data.abilities.Presence.score == 20 and data.abilities.Strength.score == 1, "Priest adjusts Presence +2 and Strength -2.")
		_check(data.feature_roll == 6 and data.traits[0].printed_roll == 666, "Physical d6 face 6 grants the printed 666 crucifix.")
		_check(data.inventory.any(func(item): return item.get("source_item_id", "") == "wrong-jesus-crucifix"), "Priest retains its special equipment.")
		_check(data.inventory.any(func(item): return item.get("source_item_id", "") == "false-dawn-nights-chariot"), "Ordinary Priest scroll resolves to its named Power.")
		_check(data.inventory.any(func(item): return item.get("source_item_id", "") == "medium-armor"), "Priest retains the class armor table with a scroll.")
		_check(data.class_rules.any(func(rule): return str(rule).contains("medium armor")), "Priest retains the medium-armor Powers exception.")
	_check(host.errors.is_empty(), "Priest physical dice match the source: %s" % str(host.errors))
	creator.free()


func test_royalty() -> void:
	var host = _host_for("wretched-royalty", 6)
	host.outcomes["Silver"] = [[1, 2, 3, 4]]
	host.outcomes["First gift"] = [[6]]
	host.outcomes["Second gift"] = [[6]]
	host.outcomes["Armor"] = [[4], [4], [3]]
	host.outcomes["Equipment first"] = [[5]]
	host.outcomes["Unclean scroll"] = [[7]]
	host.outcomes["Weapon"] = [[8]]
	var creator = _creator_for(host, "wretched-royalty")
	await _finish(creator)
	_check(host.actors.size() == 1, "Royalty creates one Character without invented companion profiles.")
	if not host.actors.is_empty():
		var data: Dictionary = host.actors[0].data
		_check(data.class_id == "wretched-royalty" and data.silver == 100, "Royalty keeps its class and 4d6 × 10 silver.")
		_check(data.traits.size() == 2 and data.traits[0].id == "horn-of-the-schleswig-lords" and data.traits[1].id == "horn-of-the-schleswig-lords", "The two independent gifts retain duplicates without discretionary rerolls.")
		var horns: Array = data.inventory.filter(func(item): return item.get("source_item_id", "") == "horn-of-the-schleswig-lords")
		_check(horns.size() == 2 and horns[0].uses == 1 and horns[1].uses == 1, "Each horn retains its own daily use.")
		_check(data.inventory.any(func(item): return item.get("source_item_id", "") == "medium-armor"), "Royalty rerolls every heavy armor result until a legal result.")
		_check(data.inventory.any(func(item): return item.get("source_item_id", "") == "flail"), "Royalty retains its class d8 weapon table even with a scroll.")
	_check(host.requests.filter(func(term): return term.name == "Armor").size() == 3, "Heavy armor requires repeated physical Rolls.")
	_check(host.errors.is_empty(), "Royalty uses only its source dice: %s" % str(host.errors))
	creator.free()


func test_fanged_hound() -> void:
	stages.clear()
	var creator = CREATOR.instantiate()
	add_child(auto_free(creator))
	if not _check(creator.has_method("select_class"), "The System creation action must offer Fanged Deserter selection."):
		creator.free()
		return
	var host = BOUNDARY.new()
	host.outcomes = {
		"Agility": [[1, 2, 3]], "Presence": [[3, 4, 5]],
		"Strength": [[4, 5, 6]], "Toughness": [[1, 1, 1]], "Hit points": [[1]],
		"Origin": [[4]], "Class feature": [[5]], "Silver": [[2, 5]], "Omens": [[4]],
		"Food": [[3]], "Equipment pack": [[2]], "Equipment first": [[1]],
		"Equipment second": [[6]], "Weapon": [[10]], "Armor": [[4]],
	}
	var entries: Array[SDK.ContentEntry] = []
	for id in ["classless-character", "fanged-deserter-character", "ancient-gore-hound"]:
		entries.append(_entry(id, "actor_definition"))
	var miniatures: Array[SDK.ContentEntry] = [_entry("creature-token", "miniature")]
	var choices: Array[Dictionary] = [{"package_id": host.PackageId(), "local_id": "creature-token", "title": "Creature"}]
	creator.configure(entries, entries[0], miniatures, true, SDK.new(host), choices)
	creator.stage_changed.connect(_stage_changed)
	creator.primary_changed.connect(_primary_changed)
	creator.begin()
	creator.select_class("fanged-deserter")
	await _finish(creator)
	_check(host.actors.size() == 2, "Confirmation creates the Character and one source-profile gore-hound.")
	if host.actors.size() == 2:
		var data: Dictionary = host.actors[0].data
		_check(data.class_id == "fanged-deserter", "The completed Actor retains its selected class.")
		_check(data.abilities.Agility == {"score": 5, "modifier": -2}, "Deserter Agility uses 3d6-1.")
		_check(data.abilities.Strength == {"score": 17, "modifier": 3}, "Deserter Strength uses 3d6+2.")
		_check(data.hit_points == 1 and data.silver == 70 and data.omens == 2, "Class HP minimum, silver and physical d2 conversion are retained.")
		_check(data.origin.contains("dogs"), "Origin roll 4 uses the actual earliest-memory table.")
		_check(host.actors[1].data.hit_points == 10, "Gore-hound has the source's fixed 10 HP.")
		_check(host.actors[1].data.attacks[0].dice == "d6", "Gore-hound bite uses d6.")
	_check(stages == [1, 2, 3, 4, 5, 6], "Creation preserves the six stages.")
	_check(host.errors.is_empty(), "Dice requests must match the supplied source outcomes: %s" % str(host.errors))
	creator.free()


func test_fanged_scrolls() -> void:
	var creator = CREATOR.instantiate()
	add_child(auto_free(creator))
	if not _check(creator.has_method("choose_scroll_disposition"), "Illiteracy requires an explicit choice for each starting scroll."):
		creator.free()
		return
	var host = BOUNDARY.new()
	host.outcomes = {
		"Agility": [[3, 3, 3]], "Presence": [[3, 3, 3]], "Strength": [[3, 3, 3]], "Toughness": [[3, 3, 3]], "Hit points": [[5]],
		"Origin": [[1]], "Class feature": [[3]], "Silver": [[1, 2]], "Omens": [[1]], "Food": [[1]],
		"Equipment pack": [[1]], "Equipment first": [[5]], "Equipment second": [[2]], "Weapon": [[10]], "Armor": [[4]],
	}
	var entries: Array[SDK.ContentEntry] = [_entry("classless-character", "actor_definition"), _entry("fanged-deserter-character", "actor_definition")]
	var miniatures: Array[SDK.ContentEntry] = [_entry("creature-token", "miniature")]
	var choices: Array[Dictionary] = [{"package_id": host.PackageId(), "local_id": "creature-token", "title": "Creature"}]
	creator.configure(entries, entries[0], miniatures, true, SDK.new(host), choices)
	creator.stage_changed.connect(_stage_changed)
	creator.primary_changed.connect(_primary_changed)
	creator.scroll_choice_requested.connect(func(slot: String): creator.choose_scroll_disposition.call_deferred(slot, "eat" if slot == "first" else "toilet-paper"))
	creator.begin()
	creator.select_class("fanged-deserter")
	await _finish(creator)
	_check(host.actors.size() == 1, "Disposed scrolls and wizard teeth grant only the Character.")
	if host.actors.size() == 1:
		var data: Dictionary = host.actors[0].data
		_check(data.scroll_dispositions.size() == 2, "Both scroll decisions survive confirmation.")
		var teeth: Array = data.inventory.filter(func(item): return item.get("source_item_id", "") == "wizard-teeth")
		_check(teeth.size() == 1 and teeth[0].quantity == 4, "The Deserter starts with four wizard teeth.")
		_check(not data.inventory.any(func(item): return str(item.get("source_item_id", "")).contains("scroll")), "Eating and toilet-paper choices retain no usable scroll.")
	_check(host.requests.filter(func(term): return term.name == "Weapon")[0].faces == 10, "Disposed scrolls do not restrict the Deserter's weapon die.")
	_check(host.errors.is_empty(), "Scroll disposition must not request a Power roll: %s" % str(host.errors))
	creator.free()


func test_gutterborn_fingersmith() -> void:
	var host = BOUNDARY.new()
	host.outcomes = {
		"Agility": [[3, 3, 3]], "Presence": [[3, 3, 3]], "Strength": [[1, 1, 1]], "Toughness": [[3, 3, 3]], "Hit points": [[6]],
		"Origin": [[3]], "Class feature": [[2]], "Silver": [[5]], "Omens": [[4]], "Food": [[1]],
		"Equipment pack": [[1]], "Equipment first": [[1]], "Equipment second": [[6]], "Weapon": [[6]], "Armor": [[4]],
	}
	var creator = CREATOR.instantiate()
	add_child(auto_free(creator))
	var entries: Array[SDK.ContentEntry] = [_entry("classless-character", "actor_definition"), _entry("gutterborn-scum-character", "actor_definition")]
	var miniatures: Array[SDK.ContentEntry] = [_entry("creature-token", "miniature")]
	var choices: Array[Dictionary] = [{"package_id": host.PackageId(), "local_id": "creature-token", "title": "Creature"}]
	creator.configure(entries, entries[0], miniatures, true, SDK.new(host), choices)
	creator.stage_changed.connect(_stage_changed)
	creator.primary_changed.connect(_primary_changed)
	creator.begin()
	creator.select_class("gutterborn-scum")
	await _finish(creator)
	_check(host.actors.size() == 1, "Gutterborn Scum completes as one Character.")
	if host.actors.size() == 1:
		var data: Dictionary = host.actors[0].data
		_check(data.class_id == "gutterborn-scum", "Gutterborn Scum survives confirmation.")
		_check(data.abilities.Strength == {"score": 1, "modifier": -3}, "Scum Strength uses 3d6-2.")
		_check(data.hit_points == 6 and data.silver == 50 and data.omens == 2, "Scum starts with Toughness+d6 HP, d6×10 silver and d2 Omens.")
		_check(data.inventory.any(func(item): return item.get("source_item_id", "") == "lockpicks"), "Filthy fingersmith grants lockpicks.")
		_check(data.inventory.any(func(item): return item.get("source_item_id", "") == "light-armor"), "Scum armor uses a physical d4 converted to d2.")
	_check(host.requests.filter(func(term): return term.name == "Weapon")[0].faces == 6, "Scum uses the d6 weapon table.")
	_check(host.errors.is_empty(), "Scum dice plan matches the source: %s" % str(host.errors))
	creator.free()

func test_hermit_hawk() -> void:
	var host = BOUNDARY.new()
	host.outcomes = {
		"Agility": [[3, 3, 3]], "Presence": [[6, 6, 6]], "Strength": [[1, 1, 1]], "Toughness": [[3, 3, 3]], "Hit points": [[4]],
		"Origin": [[6]], "Class feature": [[6]], "Silver": [[5]], "Omens": [[4]], "Food": [[1]],
		"Equipment pack": [[1]], "Equipment first": [[1]], "Equipment second": [[6]], "Hermit scroll family": [[4]], "Hermit scroll": [[7]], "Weapon": [[4]], "Armor": [[4]],
	}
	var creator = CREATOR.instantiate()
	add_child(auto_free(creator))
	var entries: Array[SDK.ContentEntry] = [_entry("classless-character", "actor_definition"), _entry("esoteric-hermit-character", "actor_definition"), _entry("hawk-as-weapon", "actor_definition")]
	var miniatures: Array[SDK.ContentEntry] = [_entry("creature-token", "miniature")]
	var choices: Array[Dictionary] = [{"package_id": host.PackageId(), "local_id": "creature-token", "title": "Creature"}]
	creator.configure(entries, entries[0], miniatures, true, SDK.new(host), choices)
	creator.stage_changed.connect(_stage_changed)
	creator.primary_changed.connect(_primary_changed)
	creator.begin()
	creator.select_class("esoteric-hermit")
	await _finish(creator)
	_check(host.actors.size() == 2, "The Hermit and source-profile hawk are created together.")
	if host.actors.size() == 2:
		var data: Dictionary = host.actors[0].data
		_check(data.class_id == "esoteric-hermit", "The Hermit class survives confirmation.")
		_check(data.abilities.Presence == {"score": 20, "modifier": 3} and data.abilities.Strength.score == 1, "Hermit ability adjustments reach both source endpoints.")
		_check(data.hit_points == 4 and data.silver == 50 and data.omens == 4, "Hermit resources use the class dice.")
		_check(data.inventory.any(func(item): return item.get("source_item_id", "") == "metzhuotl-blind-your-eye" and item.name == "Metzhuotl blind your eye" and item.rules.contains("invisible")), "The Hermit always gains its random scroll.")
		_check(host.actors[1].data.hit_points == 8 and host.actors[1].data.defence_dr == 10, "Hawk has 8 HP and DR10 defence.")
		_check(host.actors[1].data.attacks[0].dice == "d4", "Hawk claws/bite deals d4.")
	_check(host.requests.filter(func(term): return term.name == "Weapon")[0].faces == 4, "Hermit uses the d4 weapon table.")
	_check(host.errors.is_empty(), "Hermit dice plan matches the source: %s" % str(host.errors))
	creator.free()


# Every feature exercises the System action, emitted physical dice requests,
# and final Actor payload. Expectations are source facts, not profile introspection.
func test_feature_tables() -> void:
	var cases := {
		"fanged-deserter": ["crumpled-monster-mask", "brown-scimitar-of-galgenbeck", "wizard-teeth", "old-sigurds-sling", "ancient-gore-hound", "shoe-of-deaths-horse"],
		"gutterborn-scum": ["cowards-jab", "filthy-fingersmith", "abominable-gob-lobber", "escaping-fate", "excretal-stealth", "dodging-death"],
		"esoteric-hermit": ["master-of-fate", "book-of-boiling-blood", "speaker-of-truths", "initiate-of-the-invisible-college", "bard-of-the-undying", "hawk-as-weapon"],
	}
	for class_id in cases:
		for feature_index in range(6):
			var host = _host_for(class_id, feature_index + 1)
			var creator = _creator_for(host, class_id)
			await _finish(creator)
			var expected_children := 1 if (class_id == "fanged-deserter" and feature_index == 4) or (class_id == "esoteric-hermit" and feature_index == 5) else 0
			_check(host.actors.size() == 1 + expected_children, "%s feature %d creates only source-profile Actors." % [class_id, feature_index + 1])
			if not host.actors.is_empty():
				var data: Dictionary = host.actors[0].data
				_check(data.traits.size() == 1 and data.traits[0].id == cases[class_id][feature_index], "%s feature %d retains the actual trait." % [class_id, feature_index + 1])
				_check(data.origin_roll == feature_index + 1 and not data.origin.is_empty(), "Every source origin survives confirmation.")
				var item_id: String = cases[class_id][feature_index]
				if class_id == "fanged-deserter" and feature_index != 4:
					_check(data.inventory.any(func(item): return item.get("source_item_id", "") == item_id), "Fanged feature equipment is durable.")
				if class_id == "esoteric-hermit":
					_check(data.inventory.any(func(item): return item.get("source_item_id", "") == "false-dawn-nights-chariot"), "Sacred Hermit scroll family is available.")
					if feature_index == 1 or feature_index == 4:
						var grant := "book-of-boiling-blood" if feature_index == 1 else "harp"
						_check(data.inventory.any(func(item): return item.get("source_item_id", "") == grant), "Hermit feature grants its item without performing its later action.")
			_check(host.errors.is_empty(), "All features use the source dice plan: %s" % str(host.errors))
			creator.free()

func test_scroll_rerolls() -> void:
	var host = _host_for("fanged-deserter", 1)
	host.outcomes["Equipment first"] = [[5], [5], [11]]
	host.outcomes["Equipment second"] = [[2], [3]]
	host.outcomes["Red poison doses"] = [[3]]
	host.outcomes["Dog hit points"] = [[4]]
	var creator = _creator_for(host, "fanged-deserter")
	creator.scroll_choice_requested.connect(func(slot: String): creator.choose_scroll_disposition.call_deferred(slot, "reroll"))
	await _finish(creator)
	_check(host.actors.size() == 2, "Rerolling equipment into a dog creates its individual Actor.")
	if not host.actors.is_empty():
		var data: Dictionary = host.actors[0].data
		_check(data.scroll_dispositions.size() == 3, "Repeated scroll rerolls and both slots retain their required choices.")
		_check(data.inventory.any(func(item): return item.get("source_item_id", "") == "poison-red" and item.uses == 3), "Rerolled conditional equipment resolves its quantity.")
		_check(host.actors[1].data.hit_points == 6, "Rerolled dog HP uses d6+2.")
	_check(host.errors.is_empty(), "Rerolled scrolls do not request Power dice: %s" % str(host.errors))
	creator.free()

func test_discard_pending() -> void:
	for class_id in ["fanged-deserter", "gutterborn-scum", "esoteric-hermit", "wretched-royalty", "heretical-priest", "occult-herbmaster"]:
		for restart in [false, true]:
			var host = _host_for(class_id, 1)
			host.pending_roll = "Origin"
			var creator = _creator_for(host, class_id)
			for iteration in range(100):
				await get_tree().process_frame
				if host.pending_result.size() > 0:
					break
				if not disabled:
					creator.primary()
			_check(not host.pending_result.is_empty(), "The source Origin roll reaches the actual pending SDK boundary.")
			if restart:
				creator.start_over()
			else:
				creator.discard()
			host.complete_pending()
			await get_tree().process_frame
			_check(host.actors.is_empty(), "Late class roll cannot create any Actors after discard.")
			_check(host.requests.size() == 6, "Late class result cannot request another die after discard.")
			_check(stage == 1 if restart else not creator.is_active(), "Start over returns to Class; closing keeps the draft discarded.")
			creator.discard()
			creator.free()
	var host = _host_for("fanged-deserter", 1)
	host.outcomes["Equipment first"] = [[5]]
	var creator = _creator_for(host, "fanged-deserter")
	for iteration in range(160):
		await get_tree().process_frame
		if primary == "Choose scroll use":
			break
		if not disabled:
			creator.primary()
	_check(primary == "Choose scroll use", "Illiteracy blocks progression until a choice.")
	creator.start_over()
	creator.choose_scroll_disposition("first", "eat")
	await get_tree().process_frame
	_check(stage == 1 and host.actors.is_empty(), "A late scroll choice cannot revive a discarded draft.")
	creator.discard()
	creator.free()

func test_companions_projection() -> void:
	var host = _host_for("fanged-deserter", 5)
	var creator = _creator_for(host, "fanged-deserter")
	await _finish(creator)
	if not _check(host.actors.size() == 2, "Companion projection requires an actual confirmed grant."):
		creator.free()
		return
	var provenance: int = host.actors[0].data.get("creation_roll_sequence", 0)
	_check(provenance > 0 and host.actors[1].data.get("creation_roll_sequence", 0) == provenance, "Both atomic payloads retain their shared source Roll provenance.")
	var second_host = _host_for("fanged-deserter", 5)
	var second_creator = _creator_for(second_host, "fanged-deserter")
	await _finish(second_creator)
	var unrelated: Dictionary = second_host.actors[1].duplicate(true)
	unrelated.id = "other-hound"
	_check(unrelated.data.creation_roll_sequence == provenance, "Separate Worlds can repeat local Roll sequences.")
	_check(unrelated.data.creation_id != host.actors[0].data.creation_id, "Distinct creation bundles have distinct stable IDs.")
	second_creator.free()
	host.actors.append(unrelated)
	var summoned: Dictionary = unrelated.duplicate(true)
	summoned.id = "summoned-creature"
	summoned.data.erase("creation_id")
	summoned.data["summoner_actor"] = host.actors[0].id
	summoned.data["grant_source"] = "Foul Psychopomp"
	host.actors.append(summoned)
	var sheet = load(ROOT + "ui/character_sheet.tscn").instantiate()
	add_child(auto_free(sheet))
	var selected: Array[String] = []
	var placed: Array[String] = []
	sheet.companion_placement_requested.connect(func(actor: SDK.Actor): placed.append(actor.id.value))
	sheet.companion_selected.connect(func(actor: SDK.Actor): selected.append(actor.id.value))
	var miniatures: Array[SDK.ContentEntry] = []
	var choices: Array[Dictionary] = []
	sheet.set_character(SDK.Actor.new(host.actors[0]), "character", "character", miniatures, choices, SDK.new(host))
	await get_tree().process_frame
	await get_tree().process_frame
	var overview = sheet.find_child("CharacterOverview", true, false)
	_check(overview.get_node("Body/Identity/Content/Traits").text.contains("Ancient gore-hound"), "The completed sheet projects the actual feature.")
	overview.get_node("Body/Context/CompanionsSection/Content/Row/Companions").pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var companion_view = sheet.find_child("Companions", true, false)
	_check(companion_view != null, "The Character sheet opens its companions route.")
	if companion_view != null:
		var rows = companion_view.get_node("Section/Content/Items").get_children().filter(func(row): return row.has_node("Actions/Open"))
		_check(rows.size() == 2, "Starting and summoned Actors share one list; unrelated Actors stay excluded.")
		if rows.size() == 2:
			rows[0].get_node("Actions/Open").pressed.emit()
			_check(selected == ["child-1"], "Open sheet targets the individual granted Actor.")
			rows[1].get_node("Actions/Place").pressed.emit()
			_check(placed == ["summoned-creature"], "Placement targets the individual summoned Actor.")
	sheet.free()
	creator.free()

func test_atomic_refusal() -> void:
	var host = _host_for("esoteric-hermit", 6)
	host.reject_creation = true
	var creator = _creator_for(host, "esoteric-hermit")
	for iteration in range(220):
		await get_tree().process_frame
		if stage == 6:
			break
		if not disabled:
			if stage == 5:
				creator.get_node(^"View/Main/Content/Identity/Name").value = "Failed grant"
				creator.get_node(^"View/Aside/Context/Content/PreferredMiniature").pressed.emit()
			creator.primary()
	creator.primary()
	await get_tree().process_frame
	_check(host.actors.is_empty() and creator.is_active(), "An atomic refusal leaves no Character or hawk and retains the review.")
	var roll_count: int = host.requests.size()
	host.reject_creation = false
	creator.primary()
	await get_tree().process_frame
	_check(host.actors.size() == 2 and not creator.is_active(), "Retry confirms the complete bundle once.")
	_check(host.requests.size() == roll_count, "Retrying a failed confirmation never rerolls mechanics.")
	creator.free()


func test_refresh_during_creation() -> void:
	var host = _host_for("gutterborn-scum", 2)
	var creator = _creator_for(host, "gutterborn-scum")
	creator.primary()
	await get_tree().process_frame
	var entries: Array[SDK.ContentEntry] = [_entry("classless-character", "actor_definition"), _entry("gutterborn-scum-character", "actor_definition")]
	var miniatures: Array[SDK.ContentEntry] = [_entry("creature-token", "miniature")]
	var choices: Array[Dictionary] = [{"package_id": host.PackageId(), "local_id": "creature-token", "title": "Creature"}]
	# A remote Actor update refreshes the public catalogue while creation is active.
	creator.configure(entries, entries[0], miniatures, true, SDK.new(host), choices)
	await _finish(creator)
	_check(host.actors.size() == 1 and host.actors[0].data.class_id == "gutterborn-scum", "Catalogue refresh must preserve the selected class definition.")
	creator.free()


func _host_for(class_id: String, feature_roll: int):
	var host = BOUNDARY.new()
	host.outcomes = {
		"Agility": [[3, 3, 3]], "Presence": [[3, 3, 3]], "Strength": [[3, 3, 3]], "Toughness": [[3, 3, 3]], "Hit points": [[4]],
		"Origin": [[feature_roll]], "Class feature": [[feature_roll]], "Silver": [[2, 3]] if class_id == "fanged-deserter" else [[3]], "Omens": [[4]], "Food": [[1]],
		"Equipment pack": [[1]], "Equipment first": [[1]], "Equipment second": [[6]], "Weapon": [[4]], "Armor": [[4]],
	}
	if class_id == "esoteric-hermit":
		host.outcomes["Hermit scroll family"] = [[1]]
		host.outcomes["Hermit scroll"] = [[7]]
	if class_id == "wretched-royalty":
		host.outcomes["Silver"] = [[1, 2, 3, 4]]
		host.outcomes["First gift"] = [[feature_roll]]
		host.outcomes["Second gift"] = [[feature_roll]]
		host.outcomes["Armor"] = [[3]]
	elif class_id == "heretical-priest":
		host.outcomes["Silver"] = [[1, 2, 3]]
	elif class_id == "occult-herbmaster":
		host.outcomes["Silver"] = [[2, 3]]
		host.outcomes["First decoction"] = [[feature_roll]]
		host.outcomes["Second decoction"] = [[feature_roll]]
		host.outcomes["Decoction doses"] = [[4]]
	return host

func _creator_for(host, class_id: String):
	var creator = CREATOR.instantiate()
	add_child(auto_free(creator))
	var entries: Array[SDK.ContentEntry] = []
	for id in ["classless-character", "fanged-deserter-character", "gutterborn-scum-character", "esoteric-hermit-character", "wretched-royalty-character", "heretical-priest-character", "occult-herbmaster-character", "ancient-gore-hound", "hawk-as-weapon", "dog-small-but-vicious", "monkey"]:
		entries.append(_entry(id, "actor_definition"))
	var miniatures: Array[SDK.ContentEntry] = [_entry("creature-token", "miniature")]
	var choices: Array[Dictionary] = [{"package_id": host.PackageId(), "local_id": "creature-token", "title": "Creature"}]
	creator.configure(entries, entries[0], miniatures, true, SDK.new(host), choices)
	creator.stage_changed.connect(_stage_changed)
	creator.primary_changed.connect(_primary_changed)
	creator.begin()
	# Exercise the authored class button, not an implementation helper.
	var node: String = {"fanged-deserter": "FangedDeserter", "gutterborn-scum": "GutterbornScum", "esoteric-hermit": "EsotericHermit", "wretched-royalty": "WretchedRoyalty", "heretical-priest": "HereticalPriest", "occult-herbmaster": "OccultHerbmaster"}[class_id]
	creator.get_node("View/Main/Content/Class/" + node).pressed.emit()
	return creator


func _finish(creator: Node) -> void:
	for iteration in range(240):
		await get_tree().process_frame
		if not creator.is_active():
			return
		if disabled:
			continue
		if stage == 5:
			creator.get_node(^"View/Main/Content/Identity/Name").value = "Ashen Test"
			creator.get_node(^"View/Aside/Context/Content/PreferredMiniature").pressed.emit()
		creator.primary()
	_check(false, "Creation did not finish through its public actions.")

func _entry(id: String, kind: String) -> SDK.ContentEntry:
	return SDK.ContentEntry.new({"packageId": "0404eb56-ef27-4b1a-8385-27e4e3ec907e", "localId": id, "displayName": id, "available": true, "type": kind})

func _stage_changed(step: int, _title: String) -> void:
	stage = step
	if stages.is_empty() or stages[-1] != step:
		stages.append(step)

func _primary_changed(text: String, blocked: bool) -> void:
	primary = text
	disabled = blocked

func _check(condition: bool, message: String) -> bool:
	assert_bool(condition).override_failure_message(message).is_true()
	return condition

func after_test() -> void:
	await get_tree().process_frame

func before_test() -> void:
	stage = 0
	stages.clear()
	primary = ""
	disabled = false
