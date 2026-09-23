extends RefCounted

## Bare Bones pp. 46–57. Creation facts only; ongoing effects and Omen
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

	"wretched-royalty": {
  "title": "Wretched Royalty",
  "hp_faces": 6,
  "silver_count": 4,
  "omen_faces": 2,
  "ability_offsets": {},
  "weapon_faces": 8,
  "armor_faces": 4,
  "fixed_arms": true,
  "reroll_heavy_armor": true,
  "rules": [
    "Painfully average: no ability adjustments. Roll d8 for weapons and d4 for armor; reroll heavy armor.",
    "Begin with two independently rolled gifts."
  ],
  "origins": [
    "Your Wästland palace was reduced to rubble.",
    "Your caravan kingdom of Tveland fell into penury.",
    "King Fathmu IX’s brother Zigmund, your father, was murdered.",
    "The southern empire of Südglans sank into the sea.",
    "Anthelia demanded a gift of noble blood.",
    "Two young princes were kidnapped west of Bergen Chrypt."
  ],
  "features": [
    {
      "id": "blade-of-your-ancestors",
      "name": "The blade of your ancestors",
      "rules": "A magical talking sword, foppish and unreliable. Attack/defence DR10, d6+1 damage. If continually disappointed, it develops a 1-in-6 chance to attack you or your companions; the table adjudicates this.",
      "item": {
        "name": "The blade of your ancestors",
        "source_item_id": "blade-of-your-ancestors",
        "quantity": 1,
        "kind": "Weapon",
        "damage": "d6+1",
        "attack_dr": 10,
        "defence_dr": 10
      }
    },
    {
      "id": "poltroon-the-court-jester",
      "name": "Poltroon the court jester",
      "rules": "For the first two combat rounds, you and your allies gain +2 on attack/defence. Track the benefit manually.",
      "companion": "descriptive"
    },
    {
      "id": "barbarister-the-incredible-horse",
      "name": "Barbarister the incredible horse",
      "rules": "A magical, intelligent, arrogant talking horse. If persuaded to care, occasionally adds +2 to Presence tests involving logic and intellect. The table adjudicates the benefit.",
      "companion": "descriptive"
    },
    {
      "id": "hamfund-the-squire",
      "name": "Hamfund the squire",
      "rules": "Cowardly guardian of the cursed sword Eurekia. Once per combat, if Hamfund can be found, draw Eurekia: 2d6 damage. Roll d6 for each swing; on 1 Hamfund dies and Eurekia vanishes forever. Track this at the table.",
      "companion": "descriptive",
      "item": {"name": "Eurekia", "source_item_id": "eurekia", "kind": "Weapon", "damage": "2d6", "quantity": 1, "uses": 1}
    },
    {
      "id": "snake-skin-gift",
      "name": "The snake-skin gift",
      "rules": "A poisoned dagger in a silk-lined, snakeskin-bound sandalwood box. d4 damage; on a damage roll of 1, deadly poison kills the target immediately.",
      "item": {
        "name": "The snake-skin gift",
        "source_item_id": "snake-skin-gift",
        "quantity": 1,
        "kind": "Weapon",
        "damage": "d4"
      }
    },
    {
      "id": "horn-of-the-schleswig-lords",
      "name": "Horn of the Schleswig lords",
      "rules": "Once per day, sound the horn and test Presence DR12. One creature may make its next non-combat test an automatic success. Track the benefit manually.",
      "item": {
        "name": "Horn of the Schleswig lords",
        "source_item_id": "horn-of-the-schleswig-lords",
        "quantity": 1,
        "uses": 1
      }
    }
  ]
},
	"heretical-priest": {
  "title": "Heretical Priest",
  "hp_faces": 8,
  "silver_count": 3,
  "omen_faces": 4,
  "ability_offsets": {
    "Presence": 2,
    "Strength": -2
  },
  "weapon_faces": 8,
  "armor_faces": 4,
  "fixed_arms": true,
  "rules": [
    "May use Powers while wearing medium armor.",
    "Insightful: Presence 3d6+2. Frail: Strength 3d6−2. Roll d8 for weapons."
  ],
  "origins": [
    "Galgenbeck, near the cathedral of the Two-Headed Basilisks.",
    "Massacred Alliáns cult, sole survivor.",
    "The crypts of Grift.",
    "Temple ruins in the Valley of the Unfortunate Undead.",
    "One of the many Graven-Tosk thief-tunnels.",
    "Secret Bergen Chrypt church."
  ],
  "features": [
    {
      "id": "sacred-shepherds-crook",
      "name": "Sacred shepherd’s crook",
      "rules": "A human-bone crook inscribed with anti-prayers that hooks through other worlds. Staff deals 2d4 damage except to faithless humans.",
      "printed_roll": 1,
      "item": {
        "name": "Sacred shepherd’s crook",
        "source_item_id": "sacred-shepherds-crook",
        "quantity": 1,
        "kind": "Weapon",
        "damage": "2d4"
      }
    },
    {
      "id": "stolen-mitre",
      "name": "Stolen mitre",
      "rules": "While worn, defence DR10. Pulled over the ears outside battle, nearly invisible: stealth DR8.",
      "printed_roll": 2,
      "item": {
        "name": "Stolen mitre",
        "source_item_id": "stolen-mitre",
        "quantity": 1
      }
    },
    {
      "id": "list-of-sins",
      "name": "List of sins",
      "rules": "Presence DR10 reveals evil creatures in strange light. The owner defends with +2 against beings discovered this way. Track the benefit manually.",
      "printed_roll": 3,
      "item": {
        "name": "List of sins",
        "source_item_id": "list-of-sins",
        "quantity": 1
      }
    },
    {
      "id": "blasphemous-nechrubel-bible",
      "name": "The blasphemous Nechrubel Bible",
      "rules": "Read once per day and roll a die. Even: PCs heal d4 HP after five minutes of rest for the rest of the day. Odd: the GM invents d3 hallucinations only the Priest sees until sunrise. Resolve effects and duration manually.",
      "printed_roll": 4,
      "item": {
        "name": "The blasphemous Nechrubel Bible",
        "source_item_id": "blasphemous-nechrubel-bible",
        "quantity": 1,
        "uses": 1
      }
    },
    {
      "id": "stones-taken-from-thel-emas-lost-temple",
      "name": "Stones taken from Thel-Emas’ lost temple",
      "rules": "Cast the stones to reveal danger in an adjacent room. The stones may lie: test Presence DR10 for truth; after failure, cannot test again until sunset. Track the restriction manually.",
      "printed_roll": 5,
      "item": {
        "name": "Stones taken from Thel-Emas’ lost temple",
        "source_item_id": "stones-taken-from-thel-emas-lost-temple",
        "quantity": 1
      }
    },
    {
      "id": "wrong-jesus-crucifix",
      "name": "Wrong Jesus crucifix",
      "rules": "Against undead, lesser trolls and goblins, check Morale, adding or subtracting the Priest’s Presence modifier, to see whether they bow and leave.",
      "printed_roll": 666,
      "item": {
        "name": "Wrong Jesus crucifix",
        "source_item_id": "wrong-jesus-crucifix",
        "quantity": 1
      }
    }
  ]
},
	"occult-herbmaster": {
  "title": "Occult Herbmaster",
  "hp_faces": 6,
  "silver_count": 2,
  "omen_faces": 2,
  "ability_offsets": {
    "Strength": -2,
    "Toughness": 2
  },
  "weapon_faces": 6,
  "armor_faces": 2,
  "fixed_arms": true,
  "origin_faces": 8,
  "rules": [
    "Tough as wood: Toughness 3d6+2. Low in protein: Strength 3d6−2.",
    "Carry a portable laboratory. Daily materials allow two random decoctions and a total of d4 doses. Unused decoctions lose vitality after 24 hours; track eligibility and expiry manually."
  ],
  "origins": [
    "Calm isolation in the Sarkash dark.",
    "Calm isolation in the Sarkash dark.",
    "Calm isolation in the Sarkash dark.",
    "The illegal midnight markets of Schleswig.",
    "The heretic isle of Crëlut, two nautical miles east of Grift.",
    "The old frozen ruins not far from Alliáns.",
    "A little witches cottage in Galgenbeck.",
    "The ruins of the Shadow King’s manse, thick with memories."
  ],
  "features": []
}
}

const DECOCTIONS := [
  {
    "id": "red-poison-decoction",
    "name": "Red poison",
    "rules": "Toughness DR12 or lose d10 HP.",
    "item": {
      "source_item_id": "red-poison-decoction",
      "name": "Red poison",
      "kind": "Decoction",
      "dose_pool": "portable-laboratory"
    }
  },
  {
    "id": "ezumiels-vapor",
    "name": "Ezumiel’s vapor",
    "rules": "Pass a DR14 test or suffer severe hallucinations for d4 hours. The source does not select an ability; the table adjudicates it and tracks the effect.",
    "item": {
      "source_item_id": "ezumiels-vapor",
      "name": "Ezumiel’s vapor",
      "kind": "Decoction",
      "dose_pool": "portable-laboratory"
    }
  },
  {
    "id": "southern-frog-stew",
    "name": "Southern frog stew",
    "rules": "Vomit for d4 hours. Pass a DR14 test or do nothing else. The source does not select an ability; the table adjudicates it and tracks the effect.",
    "item": {
      "source_item_id": "southern-frog-stew",
      "name": "Southern frog stew",
      "kind": "Decoction",
      "dose_pool": "portable-laboratory"
    }
  },
  {
    "id": "elixir-vitalis",
    "name": "Elixir vitalis",
    "rules": "Heals d6 HP and stops infection. May be habit-forming.",
    "item": {
      "source_item_id": "elixir-vitalis",
      "name": "Elixir vitalis",
      "kind": "Decoction",
      "dose_pool": "portable-laboratory"
    }
  },
  {
    "id": "spider-owl-soup",
    "name": "Spider-owl soup",
    "rules": "See in darkness and climb on walls for 30 minutes. Track the effects manually.",
    "item": {
      "source_item_id": "spider-owl-soup",
      "name": "Spider-owl soup",
      "kind": "Decoction",
      "dose_pool": "portable-laboratory"
    }
  },
  {
    "id": "fernors-philtre",
    "name": "Fernor’s philtre",
    "rules": "Dab the translucent oil into the eye: cures infection and gives +2 on Presence tests for d4 hours. Track the benefit manually.",
    "item": {
      "source_item_id": "fernors-philtre",
      "name": "Fernor’s philtre",
      "kind": "Decoction",
      "dose_pool": "portable-laboratory"
    }
  },
  {
    "id": "hyphos-enervating-snuff",
    "name": "Hyphos’ enervating snuff",
    "rules": "Snort to go berserk: two attacks per round, defence DR14 for one fight. Causes sneezing. Track the effects manually.",
    "item": {
      "source_item_id": "hyphos-enervating-snuff",
      "name": "Hyphos’ enervating snuff",
      "kind": "Decoction",
      "dose_pool": "portable-laboratory"
    }
  },
  {
    "id": "black-poison-decoction",
    "name": "Black poison",
    "rules": "Toughness DR14 or lose d6 HP and become blind for one hour. Track blindness manually.",
    "item": {
      "source_item_id": "black-poison-decoction",
      "name": "Black poison",
      "kind": "Decoction",
      "dose_pool": "portable-laboratory"
    }
  }
]

func decoction(roll: int) -> Dictionary:
	return DECOCTIONS[roll - 1].duplicate(true) if roll > 0 and roll <= DECOCTIONS.size() else {}

func profile(class_id: String) -> Dictionary:
	return PROFILES.get(class_id, {}).duplicate(true)

func feature(class_id: String, roll: int) -> Dictionary:
	var features: Array = profile(class_id).get("features", [])
	return features[roll - 1].duplicate(true) if roll > 0 and roll <= features.size() else {}

func origin(class_id: String, roll: int) -> String:
	var origins: Array = profile(class_id).get("origins", [])
	return str(origins[roll - 1]) if roll > 0 and roll <= origins.size() else ""
