extends Area2D

signal soap_entered(data)

var type

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Soap":
		soap_entered.emit(type)
		queue_free()
# Replace with function body.
