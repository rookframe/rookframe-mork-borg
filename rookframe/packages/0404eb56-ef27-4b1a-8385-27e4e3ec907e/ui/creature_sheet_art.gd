extends RefCounted
## Authored Creature art selections; custom portrait textures bypass these defaults.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"

func heading_icon(title: String, definition: String) -> Texture2D:
	var icons := {"Attacks": preload("res://rookframe/ui/icons/character/sword.svg"), "Attacks & powers": preload("res://rookframe/ui/icons/character/sword.svg"), "Defence": preload("res://rookframe/ui/icons/character/shield.svg"), "Protection": preload("res://rookframe/ui/icons/character/shield.svg"), "Own tests": preload("res://rookframe/ui/icons/character/shield.svg"), "Inventory": preload("res://rookframe/ui/icons/character/bag.svg"), "Carried loot": preload("res://rookframe/ui/icons/character/bag.svg")}
	if definition == "bone-bowyer":
		icons["Attacks"] = preload(ROOT + "ui/icons/bow.svg")
		icons["Opening the encounter"] = preload(ROOT + "ui/icons/invisible.svg")
	return icons.get(title, preload("res://rookframe/ui/icons/character/quill.svg"))

func portrait(id: String, framed: bool = true) -> Texture2D:
	var portraits := {"seth-goblin": preload(ROOT + "ui/portraits/seth-goblin-framed.tres"), "lich": preload(ROOT + "ui/portraits/lich-framed.tres"), "bone-bowyer": preload(ROOT + "ui/portraits/bone-bowyer-framed.tres")}
	if not framed:
		portraits = {"seth-goblin": preload(ROOT + "ui/portraits/seth-goblin-sheet.png"), "lich": preload(ROOT + "ui/portraits/lich.png"), "bone-bowyer": preload(ROOT + "ui/portraits/bone-bowyer.png")}
	return portraits.get(id, preload("res://rookframe/ui/icons/character/character.svg"))
