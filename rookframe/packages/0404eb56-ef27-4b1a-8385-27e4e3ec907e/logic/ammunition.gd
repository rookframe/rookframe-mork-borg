extends RefCounted

## Inventory order determines the next stack. Only authored ammunition counters
## qualify; an arbitrary item's editable uses counter is not ammunition.
func available(items: Array, kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if kind.is_empty():
		return result
	for raw in items:
		var item: Dictionary = raw
		if str(item.get("kind", "")) != "Equipment" or str(item.get("ammunition", "")) != kind:
			continue
		var field := str(item.get("resource_field", "quantity"))
		if not field in ["quantity", "uses"]:
			continue
		var remaining: int = item.get(field, 0)
		var quantity: int = item.get("quantity", 0)
		if quantity > 0 and remaining > 0:
			result.append(item)
	return result
