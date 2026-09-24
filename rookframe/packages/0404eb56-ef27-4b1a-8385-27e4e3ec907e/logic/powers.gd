extends RefCounted

## Bare Bones pp. 34–35. Range is the approved application convention;
## Death's area and Telekinesis's movement remain separate from casting range.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const SCROLLS = preload(ROOT + "logic/starting_scrolls.gd")
const HANDLING: Dictionary = {
	"palms-open-the-southern-gate": ["immediate · RFG-290", "multiple", 30, false],
	"tongue-of-eris": ["narrative", "single", 30, true],
	"te-le-kin-esis": ["narrative", "object", 30, true],
	"lucy-fires-levitation": ["ongoing", "self", 0, true],
	"daemon-of-capillaries": ["ongoing", "single", 30, true],
	"nine-violet-signs-unknot-the-storm": ["manual allocation", "allocation", 30, true],
	"metzhuotl-blind-your-eye": ["ongoing", "single", 30, true],
	"foul-psychompomp": ["summon · RFG-291", "self", 0, false],
	"eyelid-blinds-the-mind": ["resistance; manual sleep / PC ability", "multiple", 30, true],
	"death": ["manual allocation", "area", 0, true],
	"grace-of-a-dead-saint": ["immediate · RFG-290", "multiple", 30, false],
	"grace-for-a-sinner": ["ongoing", "single", 30, true],
	"whispers-pass-the-gate": ["narrative", "single", 30, true],
	"aegis-of-sorrow": ["manual temporary HP", "single", 30, true],
	"unmet-fate": ["manual restored HP", "single", 30, true],
	"bestial-speech": ["narrative", "self", 0, true],
	"false-dawn-nights-chariot": ["ongoing", "self", 0, true],
	"hermetic-step": ["narrative", "self", 0, true],
	"roskoes-consuming-glare": ["immediate · RFG-290", "multiple", 30, false],
	"enochian-syntax": ["narrative", "single", 30, true]
}

func definition(id: String) -> Dictionary:
	var tables: Dictionary = SCROLLS.TABLES
	for family in ["unclean", "sacred"]:
		var entries: Array = tables.get(family, [])
		for raw in entries:
			var entry: Dictionary = raw
			if str(entry.source_item_id) == id:
				var result: Dictionary = entry.duplicate(true)
				var handling: Array = HANDLING.get(id, [])
				result["handling"] = str(handling[0])
				result["target_mode"] = str(handling[1])
				var reach: int = handling[2]
				var playable: bool = handling[3]
				result["range_feet"] = reach
				result["playable"] = playable
				if id == "death":
					result["area_feet"] = 30
				return result
	return {}

func parameters(id: String) -> Array[SDK.DiceTerm]:
	if id in ["te-le-kin-esis"]:
		return [SDK.DiceTerm.new("Movement (tens of feet)", 10), SDK.DiceTerm.new("Minutes", 6)]
	if id in ["lucy-fires-levitation"]:
		return [SDK.DiceTerm.new("Rounds + Presence", 10)]
	if id in ["daemon-of-capillaries", "metzhuotl-blind-your-eye"]:
		return [SDK.DiceTerm.new("Rounds", 6)]
	if id in ["nine-violet-signs-unknot-the-storm"]:
		return [SDK.DiceTerm.new("Bolts (d2)", 4)]
	if id in ["eyelid-blinds-the-mind"]:
		return [SDK.DiceTerm.new("Creatures", 4)]
	if id in ["death"]:
		return [SDK.DiceTerm.new("Shared HP loss", 10, 4)]
	if id in ["grace-for-a-sinner"]:
		return [SDK.DiceTerm.new("Bonus", 6)]
	if id in ["aegis-of-sorrow"]:
		return [SDK.DiceTerm.new("Extra HP", 6, 2)]
	if id in ["bestial-speech"]:
		return [SDK.DiceTerm.new("Minutes", 20)]
	if id in ["false-dawn-nights-chariot"]:
		return [SDK.DiceTerm.new("Minutes", 10, 3)]
	if id in ["hermetic-step"]:
		return [SDK.DiceTerm.new("Minutes", 10, 2)]
	return []

func report(id: String, values: Array[int], presence: int) -> String:
	var total := 0
	for value in values:
		total += value
	if id in ["tongue-of-eris"]:
		return "Confused for 10 minutes."
	if id in ["te-le-kin-esis"]:
		return "Move the chosen object up to %d feet for %d minutes." % [values[0] * 10, values[1]]
	if id in ["lucy-fires-levitation"]:
		return "Hover for %d rounds (Presence %+d)." % [total + presence, presence]
	if id in ["daemon-of-capillaries"]:
		return "Suffocates for %d rounds, losing d4 HP per round. Roll and apply later damage manually; no ticks are applied." % total
	if id in ["nine-violet-signs-unknot-the-storm"]:
		var damage := ""
		for value in values:
			damage += (", " if not damage.is_empty() else "") + str(value)
		return "%d bolts, damage per bolt: %s. Bolt assignment and damage allocation belong to the table. d2 count used a physical d4 halved, rounded up." % [values.size(), damage]
	if id in ["metzhuotl-blind-your-eye"]:
		return "Invisible for %d rounds or until damaged; attacking/defending with DR6." % total
	if id in ["death"]:
		return "All creatures within the 30 ft area lose a shared total of %d HP. The source leaves allocation to the table; no HP has been distributed." % total
	if id in ["grace-for-a-sinner"]:
		return "+%d on one roll (damage, tests etc.)." % total
	if id in ["whispers-pass-the-gate"]:
		return "Ask three questions to the deceased creature. Answers belong to the table."
	if id in ["aegis-of-sorrow"]:
		return "%d extra HP for 10 rounds. Manage temporary HP manually; current and maximum HP are unchanged." % total
	if id in ["unmet-fate"]:
		return "A creature dead for no more than a week is awakened with terrible memories. The source specifies no restored HP; make resurrection sheet changes manually."
	if id in ["bestial-speech"]:
		return "Speak with animals for %d minutes." % total
	if id in ["false-dawn-nights-chariot"]:
		return "Light or pitch black for %d minutes; the table chooses and handles it." % total
	if id in ["hermetic-step"]:
		return "Find all traps in your path for %d minutes." % total
	if id in ["enochian-syntax"]:
		return "One creature blindly obeys a single command. Give and resolve the command at the table."
	return ""
