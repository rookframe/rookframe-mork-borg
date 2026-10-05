extends Button
## The 40px phone rail borrows 4px from the empty top inset for its hit target.
## Stock Control hit testing keeps it out of the adjacent section-button rail.
func _has_point(point: Vector2) -> bool:
	return point.x >= 0 and point.x < size.x and point.y >= minf(0, size.y - 44) and point.y < size.y
