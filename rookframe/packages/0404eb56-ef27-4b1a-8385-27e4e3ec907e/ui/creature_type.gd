extends RefCounted
## Type roles of the Creature sheets as UI Kit label variations.
##
## A narrower canvas steps a role down instead of shrinking it by pixels:
## each entry lists the variation for desktop, tablet and phone.

const ROLES := {
	"Name": [&"RookframeTitle", &"RookframeSubtitle", &"RookframeHeading"],
	"Classification": [&"RookframeBodyMuted", &"RookframeBodyMuted", &"RookframeMeta"],
	"Section": [&"RookframeHeading", &"RookframeHeading", &"RookframeLabel"],
	"RuleTitle": [&"RookframeHeading", &"RookframeHeading", &"RookframeLabel"],
	"RuleCopy": [&"RookframeBody", &"RookframeBody", &"RookframeLabel"],
	"Caption": [&"RookframeMeta", &"RookframeMeta", &"RookframeMeta"],
	"Label": [&"RookframeLabel", &"RookframeLabel", &"RookframeLabel"],
	"Value": [&"RookframeValue", &"RookframeValue", &"RookframeHeading"],
	"Title": [&"RookframeSubtitle", &"RookframeHeading", &"RookframeHeading"],
	"Copy": [&"RookframeBody", &"RookframeBody", &"RookframeLabel"],
}


static func variation(role: String, phone: bool, tablet: bool) -> StringName:
	return ROLES[role][2 if phone else 1 if tablet else 0]


static func apply(label: Control, role: String, phone: bool, tablet: bool) -> void:
	label.theme_type_variation = variation(role, phone, tablet)
