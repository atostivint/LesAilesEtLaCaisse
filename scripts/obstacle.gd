extends Control
## Racine des obstacles (pince.tscn, clous.tscn) : le dessin est dans la scène,
## ce script ne fait que mettre la boîte à la taille de la zone qui blesse.


func setup(rect_px: Rect2) -> void:
	position = rect_px.position
	size = rect_px.size
