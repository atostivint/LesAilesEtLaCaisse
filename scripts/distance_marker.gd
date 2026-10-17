extends Node2D
## Un fanion de distance (distance_marker.tscn) : un poteau et son texte.


func setup(text: String, pos_px: Vector2, pole_height_px: float) -> void:
	position = pos_px
	$Pole.size.y = pole_height_px
	$Label.text = text
