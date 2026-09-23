extends VBoxContainer
signal mutation_requested(operation: String, arguments: Array)
signal navigate_requested(route: String, item_id: String)
func configure(data: Dictionary, _miniatures: Array) -> void:
	var count: int = data.get("omens", 0)
	get_node(^"Omens/Content/Count").text = str(count)
