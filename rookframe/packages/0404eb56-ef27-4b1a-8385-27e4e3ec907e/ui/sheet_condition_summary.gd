extends Button

func configure(data: Dictionary, condition: Dictionary, phone: bool) -> void:
	var tablet := get_viewport_rect().size.x <= 1150 and not phone
	var incident: Dictionary = data.get("broken_incident", {})
	var title := str(condition.get("title", "")).capitalize()
	var summary := "0 HP · roll d4"
	if incident.get("dead", false) or int(data.get("hit_points", 0)) < 0:
		summary = "Below 0 HP" if int(data.get("hit_points", 0)) < 0 else "Broken d4 · dead"
	elif int(incident.get("outcome", 0)) > 0:
		var remaining := maxi(0, int(incident.get("duration", 0)) - int(incident.get("elapsed", 0)))
		summary = "Complete the retained dice."
		if incident.get("treated", false):
			summary = "Bleeding stopped · 0 HP"
		elif incident.has("followup_sequence"):
			summary = "%d rounds remaining" % remaining if int(incident.get("outcome", 0)) in [1, 2] else "%dh until death unless treated" % remaining
	get_node(^"Inset/Content/Heading/Title").text = title
	get_node(^"Inset/Content/Heading/Title").add_theme_font_size_override("font_size", 17 if phone else 21 if tablet else 24)
	get_node(^"Inset/Content/Copy").text = summary
	get_node(^"Inset/Content/Copy").add_theme_font_size_override("font_size", 12 if phone else 13 if tablet else 15)
	get_node(^"Inset/Content/Link/Title").add_theme_font_size_override("font_size", 12 if phone else 14)
	get_node(^"Inset/Content").add_theme_constant_override("separation", 5 if phone else 12)
	for edge in ["left", "right", "top", "bottom"]:
		get_node(^"Inset").add_theme_constant_override("margin_" + edge, 8 if phone else 12)
	custom_minimum_size = Vector2(44, 100 if phone else 132)
	accessibility_name = title + ": " + summary + ". Show condition on Character."
