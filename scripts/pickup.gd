extends Node2D
## Une pièce à ramasser (pickup.tscn). Un enfant par matériau, nommé comme son id ("planche", "plume"...) :
## on n'affiche que celui du matériau demandé.


func setup(material_id: String, pos_px: Vector2) -> void:
	position = pos_px
	for child in get_children():
		child.visible = child.name == material_id
