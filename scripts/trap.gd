extends Area2D

signal soap_entered

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Soap":
		soap_entered.emit()
