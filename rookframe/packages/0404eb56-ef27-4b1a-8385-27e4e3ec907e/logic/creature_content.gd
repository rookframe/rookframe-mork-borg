extends RefCounted
## Published mechanical restatements and attribution, separate from live capabilities.
## Review cases Simple/Middle/Boss never enter Actor data. See docs/creature-sources.md.
const ENTRIES: Dictionary = {
	"seth-goblin": {
		"classification": "Goblin",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 58"
		},
		"reference": [
			{
				"id": "bounties",
				"name": "Bounties",
				"text": "Head 7s · Captured 150s · Dead 20s"
			}
		],
		"rule_groups": [
			{
				"title": "Attacks",
				"lane": "primary",
				"entries": [
					{
						"id": "goblin-curse",
						"name": "Goblin curse",
						"text": "An attack carries the goblin curse whether it hits or misses. Find and kill that goblin within d6 days; if it still lives, the victim permanently becomes a goblin.",
						"rolls": [
							{
								"id": "duration",
								"name": "Duration",
								"dice": "d6"
							}
						]
					}
				]
			},
			{
				"title": "Defence",
				"lane": "secondary",
				"entries": [
					{
						"id": "quick",
						"name": "Quick",
						"text": "Player attacks and defence against Seth are DR14."
					}
				]
			}
		],
		"portrait": "seth-goblin"
	},
	"bent-scum": {
		"classification": "Scum",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 58"
		},
		"reference": [
			{
				"id": "bounties",
				"name": "Bounties",
				"text": "Captured 50–120s · Dead 20–70s (wanted for serious crime)"
			}
		],
		"rule_groups": [
			{
				"title": "Special",
				"lane": "secondary",
				"entries": [
					{
						"id": "infection",
						"name": "Poisoned knife",
						"text": "A knife wound requires Toughness DR10 to avoid infection."
					},
					{
						"id": "backstab",
						"name": "Cowardly backstab",
						"text": "At the start of battle, the PC with the highest Presence tests DR14. Failure automatically hits a random party member for normal damage +3."
					}
				]
			}
		],
		"portrait": ""
	},
	"zukuma-berserker": {
		"classification": "Berserker",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 59"
		},
		"reference": [
			{
				"id": "bounties",
				"name": "Bounties",
				"text": "Dead 20s · Captured 55s · Blood per litre 3s"
			}
		],
		"rule_groups": [
			{
				"title": "Special",
				"lane": "secondary",
				"entries": [
					{
						"id": "frenzy",
						"name": "Frenzied assault",
						"text": "Attacks twice per round. Attacks against the berserker are DR10."
					},
					{
						"id": "weapon-choice",
						"name": "Wields",
						"text": "The printed d4 chooses: 1 long flail d8; 2 heavy mace d6; 3 chained sword d6; 4 huge warhammer d10.",
						"rolls": [
							{
								"id": "weapon-choice",
								"name": "Weapon choice",
								"dice": "d4"
							}
						]
					}
				]
			}
		],
		"portrait": ""
	},
	"wrat-wraith": {
		"classification": "Wraith",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 59"
		},
		"reference": [
			{
				"id": "bounties",
				"name": "Bounties",
				"text": "Captured 120s · Skull 70s · Ectoplasm 25s"
			}
		],
		"rule_groups": [
			{
				"title": "Special",
				"lane": "secondary",
				"entries": [
					{
						"id": "elusive",
						"name": "Elusive",
						"text": "Attacks against the wraith are DR14."
					},
					{
						"id": "initiative",
						"name": "Initiative",
						"text": "Always wins initiative."
					},
					{
						"id": "draining-touch",
						"name": "Draining touch",
						"text": "Touch reduces Strength, Presence and Agility by 1 for the rest of the fight."
					}
				]
			}
		],
		"portrait": ""
	},
	"belze-skeleton": {
		"classification": "Blood-drenched skeleton",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 60"
		},
		"reference": [
			{
				"id": "bounties",
				"name": "Bounties",
				"text": "Captured 35s · Destroyed 7s"
			}
		],
		"rule_groups": [
			{
				"title": "Special",
				"lane": "secondary",
				"entries": [
					{
						"id": "silent",
						"name": "Silent ambush",
						"text": "Moves without sound and attacks by surprise. It can mimic only voices it has heard."
					},
					{
						"id": "piercing",
						"name": "Piercing resistance",
						"text": "Piercing attacks against it are DR14."
					},
					{
						"id": "destruction",
						"name": "Destruction",
						"text": "A strike dealing at least 5 damage destroys it completely."
					}
				]
			}
		],
		"portrait": ""
	},
	"lich-necromancer": {
		"classification": "Undead (weak) necromancer",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 60"
		},
		"reference": [
			{
				"id": "bounties",
				"name": "Bounties",
				"text": "Captured 200s · Remains 130s · Skull 100s"
			}
		],
		"rule_groups": [
			{
				"title": "Attacks & powers",
				"lane": "primary",
				"entries": [
					{
						"id": "paralysis",
						"name": "Paralyzing touch",
						"text": "Touch paralyzes. Test Presence DR14 each round to break free."
					},
					{
						"id": "scroll-theft",
						"name": "Scroll theft",
						"text": "Each round the lich may take the contents of a nearby scroll and use its Power against the scroll’s owner."
					}
				]
			},
			{
				"title": "Defence",
				"lane": "secondary",
				"entries": [
					{
						"id": "power-suppression",
						"name": "Power suppression",
						"text": "No one can use Powers near the lich."
					}
				]
			}
		],
		"portrait": "lich"
	},
	"arbint-troll": {
		"classification": "Troll",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 60"
		},
		"reference": [
			{
				"id": "bounties",
				"name": "Bounties",
				"text": "Captured 200s · Corpse 70s · Horn 25s"
			}
		],
		"rule_groups": [
			{
				"title": "Special",
				"lane": "secondary",
				"entries": [
					{
						"id": "easy-hit",
						"name": "Easy to hit",
						"text": "Attacks against the troll are DR10."
					},
					{
						"id": "retreat",
						"name": "Morale",
						"text": "Usually retreats when badly wounded and remembers who hurt it."
					},
					{
						"id": "growth",
						"name": "Growth",
						"text": "Every HP healed also increases maximum HP by 1. Each return adds d6 to its damage.",
						"rolls": [
							{
								"id": "growth",
								"name": "Added damage",
								"dice": "d6"
							}
						]
					}
				]
			}
		],
		"portrait": ""
	},
	"nodh-zombie": {
		"classification": "Zombie",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 61"
		},
		"reference": [
			{
				"id": "bounties",
				"name": "Bounties",
				"text": "Captured 30s · Blood per litre 5s"
			}
		],
		"rule_groups": [
			{
				"title": "Special",
				"lane": "secondary",
				"entries": [
					{
						"id": "bite-infection",
						"name": "Infected bite",
						"text": "A bitten victim tests Toughness DR8 or dies within two days and then rises as a zombie."
					},
					{
						"id": "cure",
						"name": "Cure",
						"text": "The rumored cure or vaccine is atop a pale mountain in a dark-leaved forest. King Fathmu IX of Wästland knows that forest’s name and location."
					}
				]
			}
		],
		"portrait": ""
	},
	"lady-porcelain": {
		"classification": "Undead doll",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 61"
		},
		"reference": [
			{
				"id": "bounties",
				"name": "Bounties",
				"text": "Head 20s · Captured 80s"
			}
		],
		"rule_groups": [
			{
				"title": "Special",
				"lane": "secondary",
				"entries": [
					{
						"id": "mad-gaze",
						"name": "Mad gaze",
						"text": "At combat’s start, Presence DR12 avoids being frozen with fear for d4 rounds.",
						"rolls": [
							{
								"id": "fear-duration",
								"name": "Fear duration",
								"dice": "d4"
							}
						]
					}
				]
			}
		],
		"portrait": ""
	},
	"thinx-grotesque": {
		"classification": "Grotesque",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 62"
		},
		"reference": [
			{
				"id": "bounties",
				"name": "Bounties",
				"text": "Captured 190s · Dead intact 100s · Dead in pieces 10s"
			}
		],
		"rule_groups": [],
		"portrait": ""
	},
	"aland-wickhead": {
		"classification": "Wickhead knife-wielder",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 62"
		},
		"reference": [
			{
				"id": "bounties",
				"name": "Bounties",
				"text": "Captured 60s · Decapitated lantern 15s · Corpse 20s"
			}
		],
		"rule_groups": [
			{
				"title": "Special",
				"lane": "secondary",
				"entries": [
					{
						"id": "infection",
						"name": "Filthy knife",
						"text": "Wounds have a 25% chance of infection."
					},
					{
						"id": "light",
						"name": "Light and darkness",
						"text": "Can extinguish nearby light sources, ignite its own blinding light, attack, and disappear into the dark."
					}
				]
			}
		],
		"portrait": ""
	},
	"eulotha-wyvern": {
		"classification": "Wyvern",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 62"
		},
		"reference": [
			{
				"id": "bounties",
				"name": "Bounties",
				"text": "Captured 200s · Corpse 100s · Poison gland 60s · Tail spike 60s"
			}
		],
		"rule_groups": [
			{
				"title": "Special",
				"lane": "secondary",
				"entries": [
					{
						"id": "attack-choice",
						"name": "Attack choice",
						"text": "60% chance of Bite; otherwise Sting."
					},
					{
						"id": "sting-paralysis",
						"name": "Sting paralysis",
						"text": "Toughness DR14 avoids one hour of painful paralysis."
					}
				]
			}
		],
		"portrait": ""
	},
	"ancient-gore-hound": {
		"classification": "",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 47"
		},
		"reference": [],
		"rule_groups": [
			{
				"title": "Own tests",
				"lane": "primary",
				"entries": [
					{
						"id": "own-defence",
						"name": "Defence",
						"text": "Unmodified d20 against DR12.",
						"own_test": "defence"
					}
				]
			},
			{
				"title": "Special rules",
				"lane": "secondary",
				"entries": [
					{
						"id": "companion-rules",
						"name": "Companion",
						"text": "Sniffs out treasure in debris. Frenzied around goblins and berserkers."
					}
				]
			}
		],
		"portrait": ""
	},
	"hawk-as-weapon": {
		"classification": "",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 51"
		},
		"reference": [],
		"rule_groups": [
			{
				"title": "Own tests",
				"lane": "primary",
				"entries": [
					{
						"id": "own-defence",
						"name": "Defence",
						"text": "Unmodified d20 against DR10.",
						"own_test": "defence"
					}
				]
			},
			{
				"title": "Special rules",
				"lane": "secondary",
				"entries": [
					{
						"id": "companion-rules",
						"name": "Companion",
						"text": "Loyal only to its Hermit, who understands its cries. Keeps watch, scouts and attacks."
					}
				]
			}
		],
		"portrait": ""
	},
	"dog-small-but-vicious": {
		"classification": "",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 22"
		},
		"reference": [
			{
				"id": "starting-hp",
				"name": "Starting HP",
				"text": "d6+2"
			},
			{
				"id": "behavior",
				"name": "Companion",
				"text": "Obeys only its owner."
			}
		],
		"rule_groups": [],
		"portrait": "",
		"hit_points_formula": "d6+2"
	},
	"monkey": {
		"classification": "",
		"source": {
			"title": "MÖRK BORG Bare Bones Edition",
			"url": "https://jnohr.itch.io/mrk-borg-free",
			"page": "p. 22"
		},
		"reference": [
			{
				"id": "starting-hp",
				"name": "Starting HP",
				"text": "d4+2"
			},
			{
				"id": "behavior",
				"name": "Companion",
				"text": "Ignores its owner but loves them."
			}
		],
		"rule_groups": [],
		"portrait": "",
		"hit_points_formula": "d4+2"
	},
	"bone-bowyer": {
		"classification": "MÖRK BORG CULT · Matthew Bottiglieri",
		"source": {
			"title": "The Bone Bowyer · MÖRK BORG CULT",
			"url": "https://drive.google.com/file/d/1Rng4eHebeiu6z6te_HNmzCLnMGIL8fXy/view",
			"page": "Single-page release",
			"author": "Matthew Bottiglieri · Graphic design and art Johan Nohr"
		},
		"reference": [],
		"rule_groups": [
			{
				"title": "Opening the encounter",
				"lane": "secondary",
				"entries": [
					{
						"id": "ambush",
						"name": "Ambush",
						"text": "Test DR12 to detect the Bowyer. Failure grants it two free shots; the source does not name an ability for this test."
					}
				]
			},
			{
				"title": "Reference",
				"lane": "secondary",
				"entries": [
					{
						"id": "bow-reference",
						"name": "The Bowyer’s bow",
						"text": "The bow deals d6 damage. A miss sends the arrow toward another random creature nearby; repeat until it hits. It cannot target or harm the Bone Bowyer."
					},
					{
						"id": "commission",
						"name": "Unsavory services",
						"text": "The Bowyer may craft a bow for a wicked character who completes a task: abduct a child from a nearby village and bring them to the Bowyer; cruelly murder kin; desecrate a shrine or church; sow discord; spread disease; or burn a heretic."
					}
				]
			}
		],
		"portrait": "bone-bowyer"
	}
}

func details(definition: String) -> Dictionary:
	if definition == "seth-goblin":
		return ENTRIES["seth-goblin"].duplicate(true)
	if definition == "bent-scum":
		return ENTRIES["bent-scum"].duplicate(true)
	if definition == "zukuma-berserker":
		return ENTRIES["zukuma-berserker"].duplicate(true)
	if definition == "wrat-wraith":
		return ENTRIES["wrat-wraith"].duplicate(true)
	if definition == "belze-skeleton":
		return ENTRIES["belze-skeleton"].duplicate(true)
	if definition == "lich-necromancer":
		return ENTRIES["lich-necromancer"].duplicate(true)
	if definition == "arbint-troll":
		return ENTRIES["arbint-troll"].duplicate(true)
	if definition == "nodh-zombie":
		return ENTRIES["nodh-zombie"].duplicate(true)
	if definition == "lady-porcelain":
		return ENTRIES["lady-porcelain"].duplicate(true)
	if definition == "thinx-grotesque":
		return ENTRIES["thinx-grotesque"].duplicate(true)
	if definition == "aland-wickhead":
		return ENTRIES["aland-wickhead"].duplicate(true)
	if definition == "eulotha-wyvern":
		return ENTRIES["eulotha-wyvern"].duplicate(true)
	if definition == "ancient-gore-hound":
		return ENTRIES["ancient-gore-hound"].duplicate(true)
	if definition == "hawk-as-weapon":
		return ENTRIES["hawk-as-weapon"].duplicate(true)
	if definition == "dog-small-but-vicious":
		return ENTRIES["dog-small-but-vicious"].duplicate(true)
	if definition == "monkey":
		return ENTRIES["monkey"].duplicate(true)
	if definition == "bone-bowyer":
		return ENTRIES["bone-bowyer"].duplicate(true)
	return {}
