extends HBoxContainer
## Authored correction fields share the approved column proportions.
func configure(weights: Array, count: int) -> void:
	var columns = [get_node(^"First"), get_node(^"Second"), get_node(^"Third")]
	for index in range(3):
		columns[index].visible = index < count
		columns[index].size_flags_stretch_ratio = float(weights[mini(index, weights.size() - 1)])

func slot(index: int) -> Control:
	if index == 0:
		return get_node(^"First")
	if index == 1:
		return get_node(^"Second")
	return get_node(^"Third")
