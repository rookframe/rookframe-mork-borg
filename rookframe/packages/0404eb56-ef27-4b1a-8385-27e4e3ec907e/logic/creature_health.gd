extends RefCounted
## Creature death is derived only from valid accepted HP, never a correction draft.
const MAX_VALUE := 9223372036854775807
const MIN_VALUE := -9223372036854775807 - 1

func valid(data: Dictionary) -> bool:
	return typeof(data.get("hit_points")) == TYPE_INT

func is_dead(data: Dictionary) -> bool:
	return valid(data) and int(data.hit_points) <= 0

func can_roll(data: Dictionary) -> bool:
	return valid(data) and not is_dead(data)

func integer(text: String) -> Dictionary:
	var digits: String = text.strip_edges()
	if not digits.is_valid_int():
		return {"ok": false, "message": "Enter a whole number."}
	digits = digits.trim_prefix("+")
	var negative := digits.begins_with("-")
	digits = digits.trim_prefix("-")
	while digits.length() > 1 and digits.begins_with("0"):
		digits = digits.trim_prefix("0")
	var limit := "9223372036854775808" if negative else "9223372036854775807"
	if digits.length() > 19 or digits.length() == 19 and digits > limit:
		return {"ok": false, "message": "That value exceeds supported whole-number capacity."}
	return {"ok": true, "value": int(("-" if negative else "") + digits)}

func amount(text: String) -> Dictionary:
	var result := integer(text)
	if not result.ok:
		return result
	if int(result.value) < 1:
		return {"ok": false, "message": "Enter a positive whole amount."}
	return result

func adjusted(data: Dictionary, operation: String, value: int) -> Dictionary:
	if not valid(data):
		return {"ok": false, "message": "HP is unavailable. Use Edit sheet to correct it."}
	var current: int = data.hit_points
	if operation == "heal":
		if current > MAX_VALUE - value:
			return {"ok": false, "message": "That adjustment exceeds supported HP capacity."}
		return {"ok": true, "value": current + value}
	if operation == "damage":
		if current < MIN_VALUE + value:
			return {"ok": false, "message": "That adjustment exceeds supported HP capacity."}
		return {"ok": true, "value": current - value}
	return {"ok": false, "message": "Choose Apply damage or Heal."}
