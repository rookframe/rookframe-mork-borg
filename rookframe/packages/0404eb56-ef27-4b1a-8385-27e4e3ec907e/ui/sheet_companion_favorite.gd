extends HBoxContainer
signal favorite_changed(key: String, starred: bool)
const STAR = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/sheet_favorite.gd")
@onready var _title: Label = get_node(^"Title")
@onready var _star: STAR = get_node(^"Favorite")

func _ready() -> void:
	_star.favorite_changed.connect(_changed)

func configure(entry: Dictionary, owner: bool, busy: bool) -> void:
	_title.text = str(entry.get("name", "Attack"))
	_star.configure(entry, owner, busy)

func _changed(key: String, starred: bool) -> void:
	favorite_changed.emit(key, starred)
