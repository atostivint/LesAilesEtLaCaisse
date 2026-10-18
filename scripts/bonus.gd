extends Area2D

signal soap_entered(material: MaterialData)

var material_data: MaterialData


func setup(data: MaterialData) -> void:
	material_data = data
	$MateriauPapier.texture = material_data.icone

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Soap":
		if material_data == null:
			push_error("Bonus: configure its MaterialData before collecting it.")
			return
		soap_entered.emit(material_data)
		queue_free()
