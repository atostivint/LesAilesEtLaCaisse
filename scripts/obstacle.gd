extends CharacterBody2D
## Racine des obstacles (pince.tscn, clous.tscn) : le dessin est dans la scène,
## ce script ne fait que mettre la boîte à la taille de la zone qui blesse.

@onready var collision: CollisionShape2D = $CollisionShape2D


func setup(rect_px: Rect2) -> void:
	position = rect_px.position
	var shape := RectangleShape2D.new()
	shape.size = rect_px.size
	collision.shape = shape
	collision.position = rect_px.size * 0.5
