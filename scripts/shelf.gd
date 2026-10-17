extends Panel
## Une étagère (shelf.tscn) : la planche est à la largeur voulue, les deux équerres restent près des bouts.


func setup(top_left: Vector2, plank_size: Vector2) -> void:
	position = top_left
	size = plank_size
	$BracketLeft.position = Vector2(plank_size.x * 0.15, plank_size.y)
	$BracketRight.position = Vector2(plank_size.x * 0.85 - 30.0, plank_size.y)
