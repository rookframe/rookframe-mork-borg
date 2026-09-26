extends RefCounted
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")

func describe(sdk: SDK, source: SDK.RookId, reach: float) -> String:
	var targets: SDK.TargetSnapshotResult = await sdk.targeting.snapshot()
	if not targets.ok:
		return targets.message
	var summary := ""
	for rook in targets.snapshot.rooks:
		var identity: SDK.PublicIdentityResult = sdk.public_identities.read(rook)
		var line := identity.public_identity.label if identity.ok else sdk.translations.text("Creature")
		if source != null:
			var distance: SDK.DistanceResult = sdk.scenes.distance(source, rook)
			if distance.ok:
				var feet := distance.distance / 0.3048
				line += sdk.translations.text("\n%.1f ft · %s") % [feet, sdk.translations.text("In range") if feet <= reach + 0.00001 else sdk.translations.text("Out of range")]
		summary += ("\n" if not summary.is_empty() else "") + line
	return summary if not summary.is_empty() else sdk.translations.text("Choose one target")
