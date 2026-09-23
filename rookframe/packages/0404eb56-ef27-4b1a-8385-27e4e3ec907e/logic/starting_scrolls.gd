extends RefCounted

## Bare Bones Powers tables, pp. 32–33; effects remain table managed.
const TABLES: Dictionary = {
  "unclean": [
    {
      "name": "Palms open the southern gate",
      "source_item_id": "palms-open-the-southern-gate",
      "rules": "A ball of fire hits d2 creatures dealing d8 damage per creature",
      "kind": "Scroll",
      "family": "unclean"
    },
    {
      "name": "Tongue of eris",
      "source_item_id": "tongue-of-eris",
      "rules": "A creature of your choice is confused for 10 minutes",
      "kind": "Scroll",
      "family": "unclean"
    },
    {
      "name": "Te-le-kin-esis",
      "source_item_id": "te-le-kin-esis",
      "rules": "Move an object up to d10×10 feet for d6 minutes",
      "kind": "Scroll",
      "family": "unclean"
    },
    {
      "name": "Lucy-fires levitation",
      "source_item_id": "lucy-fires-levitation",
      "rules": "Hover for Presence + d10 rounds",
      "kind": "Scroll",
      "family": "unclean"
    },
    {
      "name": "Daemon of capillaries",
      "source_item_id": "daemon-of-capillaries",
      "rules": "One creature suffocates for d6 rounds, losing d4 hp per round",
      "kind": "Scroll",
      "family": "unclean"
    },
    {
      "name": "Nine violet signs unknot the storm",
      "source_item_id": "nine-violet-signs-unknot-the-storm",
      "rules": "Produce d2 lightning bolts dealing d6 damage each",
      "kind": "Scroll",
      "family": "unclean"
    },
    {
      "name": "Metzhuotl blind your eye",
      "source_item_id": "metzhuotl-blind-your-eye",
      "rules": "A creature becomes invisible for d6 rounds or until it is damaged, attacking/defending with dr6",
      "kind": "Scroll",
      "family": "unclean"
    },
    {
      "name": "Foul psychompomp",
      "source_item_id": "foul-psychompomp",
      "rules": "Summon (d6): 1–3 d4 skeletons 4–6 d4 zombies",
      "kind": "Scroll",
      "family": "unclean"
    },
    {
      "name": "Eyelid blinds the mind",
      "source_item_id": "eyelid-blinds-the-mind",
      "rules": "d4 creatures fall asleep for one hour unless they succeed a dr14 test",
      "kind": "Scroll",
      "family": "unclean"
    },
    {
      "name": "Death",
      "source_item_id": "death",
      "rules": "All creatures within 30 feet lose a total of 4d10 hp",
      "kind": "Scroll",
      "family": "unclean"
    }
  ],
  "sacred": [
    {
      "name": "Grace of a dead saint",
      "source_item_id": "grace-of-a-dead-saint",
      "rules": "d2 creatures regain d10 hp each",
      "kind": "Scroll",
      "family": "sacred"
    },
    {
      "name": "Grace for a sinner",
      "source_item_id": "grace-for-a-sinner",
      "rules": "A creature of your choice gets +d6 on one roll (damage, tests etc.)",
      "kind": "Scroll",
      "family": "sacred"
    },
    {
      "name": "Whispers pass the gate",
      "source_item_id": "whispers-pass-the-gate",
      "rules": "Ask three questions to a deceased creature",
      "kind": "Scroll",
      "family": "sacred"
    },
    {
      "name": "Aegis of sorrow",
      "source_item_id": "aegis-of-sorrow",
      "rules": "A creature of your choice gains 2d6 extra hp for 10 rounds",
      "kind": "Scroll",
      "family": "sacred"
    },
    {
      "name": "Unmet fate",
      "source_item_id": "unmet-fate",
      "rules": "One creature, dead for no more than a week, is awakened with terrible memories",
      "kind": "Scroll",
      "family": "sacred"
    },
    {
      "name": "Bestial speech",
      "source_item_id": "bestial-speech",
      "rules": "You may speak with animals for d20 minutes",
      "kind": "Scroll",
      "family": "sacred"
    },
    {
      "name": "False dawn/night's chariot",
      "source_item_id": "false-dawn-nights-chariot",
      "rules": "Light or pitch black for 3d10 minutes",
      "kind": "Scroll",
      "family": "sacred"
    },
    {
      "name": "Hermetic step",
      "source_item_id": "hermetic-step",
      "rules": "You find all traps in your path for 2d10 minutes",
      "kind": "Scroll",
      "family": "sacred"
    },
    {
      "name": "Roskoe's consuming glare",
      "source_item_id": "roskoes-consuming-glare",
      "rules": "d4 creatures lose d8 hp each",
      "kind": "Scroll",
      "family": "sacred"
    },
    {
      "name": "Enochian syntax",
      "source_item_id": "enochian-syntax",
      "rules": "One creature blindly obeys a single command",
      "kind": "Scroll",
      "family": "sacred"
    }
  ]
}

func item(family: String, roll: int) -> Dictionary:
	var entries: Array = TABLES.get(family, [])
	if roll < 1 or roll > entries.size():
		return {}
	var source: Dictionary = entries[roll - 1]
	var result: Dictionary = source.duplicate(true)
	result["roll"] = roll
	return result
