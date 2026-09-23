extends VBoxContainer

signal appearance_save_requested(index: int)

var _miniature_choices: Array[Dictionary] = []
var _appearance_choice_index := 0

func _ready() -> void:
	get_node(^"Default/Content/Row/Details/Choose").pressed.connect(_choose)


func configure(data: Dictionary, _miniature_count: int, miniature_choices: Array[Dictionary]) -> void:
	_miniature_choices = miniature_choices
	var preferred: Dictionary = data.get("preferred_miniature", {})
	var title := "No Miniature selected"
	var local_id: String = preferred.get("local_id", "")
	for index in range(_miniature_choices.size()):
		var choice: Dictionary = _miniature_choices[index]
		if str(choice.get("local_id", "")) == local_id:
			_appearance_choice_index = index + 1
			title = str(choice.get("title", "Miniature"))
	get_node(^"Default/Content/Row/Details/Title").text = title
	get_node(^"Default/Content/Row/Details/Choose").disabled = _miniature_choices.is_empty()


func _choose() -> void:
	var index := _appearance_choice_index + 1
	if index > _miniature_choices.size():
		index = 1
	if not _miniature_choices.is_empty():
		appearance_save_requested.emit(index)
