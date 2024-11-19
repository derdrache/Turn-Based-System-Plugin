extends Button

func _on_pressed() -> void:
	var turnBasedController: TurnBasedController = get_tree().get_first_node_in_group("turnBasedController")
	print(turnBasedController.get_active_character().name)
