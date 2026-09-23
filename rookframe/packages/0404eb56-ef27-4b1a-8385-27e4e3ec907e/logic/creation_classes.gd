extends RefCounted

## Bare Bones pp. 46–47. Creation facts only; ongoing effects and Omen
## benefits remain table-managed. Returned snapshots never mutate this source.
const PROFILES := {
	"classless": {"title": "No Class", "hp_faces": 8, "silver_count": 2, "omen_faces": 2, "ability_offsets": {}, "weapon_faces": 10, "armor_faces": 4, "rules": [], "origins": [], "features": []},
	"fanged-deserter": {
		"title": "Fanged Deserter", "hp_faces": 10, "silver_count": 2, "omen_faces": 2,
		"ability_offsets": {"Agility": -1, "Presence": -1, "Strength": 2}, "weapon_faces": 10, "armor_faces": 4,
		"rules": ["Bite: DR10, d6 damage at close range. On 1–2 on d6 the enemy gains a free attack.", "Normal Agility tests are DR14; defence is excluded.", "Illiterate: cannot understand scrolls. Reroll starting scroll equipment, eat it, or use it as toilet paper."],
		"origins": ["A burnt-black building in Sarkash. Your home?", "A derelict rotting ship rolling endlessly across a grey sea.", "A brothel in Schleswig. Quite a friendly environment.", "Sleeping with dogs in the corner of an inn, waiting for someone to return.", "Following an army in eastern Wästland.", "Suckling a wolf in the wild of Bergen Chrypt."],
		"features": [
			{"id": "crumpled-monster-mask", "name": "Crumpled monster mask", "rules": "While worn, lesser creatures such as goblins, gnoums and children check Morale every round. Resolve ongoing effects manually.", "item": {"name": "Crumpled monster mask", "source_item_id": "crumpled-monster-mask", "quantity": 1}},
			{"id": "brown-scimitar-of-galgenbeck", "name": "The brown scimitar of Galgenbeck", "rules": "d6 damage; attack and defence DR10 while wielded. A wounded enemy has a 1-in-6 chance of sepsis and death in 10 minutes; track that consequence manually.", "item": {"name": "The brown scimitar of Galgenbeck", "source_item_id": "brown-scimitar-of-galgenbeck", "kind": "Weapon", "damage": "d6", "attack_dr": 10, "defence_dr": 10, "quantity": 1}},
			{"id": "wizard-teeth", "name": "Wizard teeth", "rules": "Four teeth. Before battle roll d6 for each; each 6 makes one attack deal maximum damage. The table tracks these benefits.", "item": {"name": "Wizard teeth", "source_item_id": "wizard-teeth", "quantity": 4}},
			{"id": "old-sigurds-sling", "name": "Old Sigûrd’s sling", "rules": "2d4 damage; uses fist-sized rocks.", "item": {"name": "Old Sigûrd’s sling", "source_item_id": "old-sigurds-sling", "kind": "Weapon", "damage": "2d4", "quantity": 1}},
			{"id": "ancient-gore-hound", "name": "Ancient gore-hound", "rules": "Sniffs out treasure in debris. Bite d6, attack DR10, defence DR12, HP 10. Frenzied around goblins and berserkers.", "creature": "ancient-gore-hound"},
			{"id": "shoe-of-deaths-horse", "name": "The shoe of Death’s horse", "rules": "Attack DR10, d4 damage. A 1-in-6 chance instantly kills small-to-medium creatures. Returns to the wielder.", "item": {"name": "The shoe of Death’s horse", "source_item_id": "shoe-of-deaths-horse", "kind": "Weapon", "damage": "d4", "attack_dr": 10, "quantity": 1}},
		],
	},
	"gutterborn-scum": {
	  "title": "Gutterborn Scum",
	  "hp_faces": 6,
	  "silver_count": 1,
	  "omen_faces": 2,
	  "ability_offsets": {
	    "Strength": -2
	  },
	  "weapon_faces": 6,
	  "armor_faces": 2,
	  "rules": [
	    "All Presence and Agility tests have their DR reduced by 2 (normal tests DR10).",
	    "On first getting better, roll another specialty. From the second improvement, you may reroll either or both specialties; resolve improvements at the table."
	  ],
	  "origins": [
	    "Dumped onto a moving shit-cart still in your birth caul.",
	    "Mother hanged from a tree outside Galgenbeck; you fell from the corpse.",
	    "Raised by rats in the gutters of Grift.",
	    "Kicked and beaten beneath a baker’s table in Schleswig.",
	    "Escaped the Tvelandian orphanarium.",
	    "Educated by outlaws in a hovel south of Alliáns."
	  ],
	  "features": [
	    {
	      "id": "cowards-jab",
	      "name": "Coward’s jab",
	      "rules": "When attacking by surprise, test Agility DR10. Success automatically hits once with a light one-handed weapon for normal damage +3."
	    },
	    {
	      "id": "filthy-fingersmith",
	      "name": "Filthy fingersmith",
	      "rules": "Pick pockets and locks with an Agility DR8 test. Begin with lockpicks.",
	      "item": {
	        "name": "Lockpicks",
	        "source_item_id": "lockpicks",
	        "quantity": 1
	      }
	    },
	    {
	      "id": "abominable-gob-lobber",
	      "name": "Abominable gob lobber",
	      "rules": "Spit d2 times per fight at short range with Presence DR8. Targets are blinded, retching and vomiting for d4 rounds. Witnesses test Toughness to avoid vomiting: PCs DR10, enemies DR12. Track effects and rounds manually."
	    },
	    {
	      "id": "escaping-fate",
	      "name": "Escaping fate",
	      "rules": "Each Omen use has a 50% chance not to spend it. Resolve and track this benefit manually."
	    },
	    {
	      "id": "excretal-stealth",
	      "name": "Excretal stealth",
	      "rules": "When hidden in muck, debris and filth, noticing you requires Presence DR16."
	    },
	    {
	      "id": "dodging-death",
	      "name": "Dodging death",
	      "rules": "On death, if survival is at all possible, there is a 50% chance you survived. After 10 rounds return with d4 HP and an unlikely explanation. Resolve and track this manually."
	    }
	  ]
	},

	"esoteric-hermit": {
	  "title": "Esoteric Hermit",
	  "hp_faces": 4,
	  "silver_count": 1,
	  "omen_faces": 4,
	  "ability_offsets": {
	    "Presence": 2,
	    "Strength": -2
	  },
	  "weapon_faces": 4,
	  "armor_faces": 2,
	  "rules": [
	    "Begin with ordinary equipment plus one random sacred or unclean scroll."
	  ],
	  "origins": [
	    "Awakening, adult, in a ritual circle underneath the northern bridge to Grift.",
	    "Wandered, memoryless, from the mouth of a cavern at the cliffs of Terion.",
	    "Single child survivor of an incident in the Valley of the Unfortunate Undead.",
	    "Dying of plague in a Bergen Chrypt hovel, you touched something from outside.",
	    "An average individual until you encountered something in a dim glade in Sarkash.",
	    "Raised on a lonely island in Lake Onda; no one else has heard of it and you cannot return."
	  ],
	  "features": [
	    {
	      "id": "master-of-fate",
	      "name": "Master of fate",
	      "rules": "Know the right way with a Presence DR8 test."
	    },
	    {
	      "id": "book-of-boiling-blood",
	      "name": "Book of boiling blood",
	      "rules": "Read once per day. An enemy tests DR12 to prevent it; on failure, d2 Berserker-slayers appear. Roll d6: 1–4 they fight alongside you; 5–6 they try to kill you and destroy the book. They return to imprisonment after battle. Resolve the summons and duration at the table.",
	      "item": {
	        "name": "Book of boiling blood",
	        "source_item_id": "book-of-boiling-blood",
	        "quantity": 1
	      }
	    },
	    {
	      "id": "speaker-of-truths",
	      "name": "Speaker of truths",
	      "rules": "Twice per day, lower the DR of a chosen creature’s next test by 4. Track uses and the benefit manually."
	    },
	    {
	      "id": "initiate-of-the-invisible-college",
	      "name": "Initiate of the Invisible College",
	      "rules": "Once per day summon d2 scrolls, each usable once. Roll d4: 1–2 sacred, 3–4 unclean. Unused scrolls turn to ash at sunrise. Resolve summons and track uses and expiry manually."
	    },
	    {
	      "id": "bard-of-the-undying",
	      "name": "Bard of the Undying",
	      "rules": "Music from your harp gives +d4 on reaction rolls.",
	      "item": {
	        "name": "Harp",
	        "source_item_id": "harp",
	        "quantity": 1
	      }
	    },
	    {
	      "id": "hawk-as-weapon",
	      "name": "Hawk as weapon",
	      "rules": "A crafty, almost-intelligent hawk is loyal only to you. You understand its cries as it watches, scouts and attacks. Attack and defence DR10; claws/bite d4; HP 8.",
	      "creature": "hawk-as-weapon"
	    }
	  ]
	},

}

func profile(class_id: String) -> Dictionary:
	return PROFILES.get(class_id, {}).duplicate(true)

func feature(class_id: String, roll: int) -> Dictionary:
	var features: Array = profile(class_id).get("features", [])
	return features[roll - 1].duplicate(true) if roll > 0 and roll <= features.size() else {}

func origin(class_id: String, roll: int) -> String:
	var origins: Array = profile(class_id).get("origins", [])
	return str(origins[roll - 1]) if roll > 0 and roll <= origins.size() else ""
