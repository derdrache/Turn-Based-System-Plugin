@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type(
		"TurnBasedController", 
		"Node", 
		preload("res://addons/Turn_Based_System/nodes/turn_based_controller/turn_based_controller.gd"), 
		preload("res://addons/Turn_Based_System/assets/icons/groupControl.png")
	)
	add_custom_type(
		"TurnBasedAgent", 
		"Node", 
		preload("res://addons/Turn_Based_System/nodes/turn_based_agent/turn_based_agent.gd"), 
		preload("res://addons/Turn_Based_System/assets/icons/agent.png")
	)
	add_custom_type(
		"CommandMenu", 
		"Control", 
		preload("res://addons/Turn_Based_System/nodes/command_menu/comand_menu.gd"), 
		preload("res://addons/Turn_Based_System/assets/icons/VBoxContainer.svg")
	)
	add_custom_type(
		"TurnOrderBar", 
		"Control", 
		preload("res://addons/Turn_Based_System/nodes/command_menu/comand_menu.gd"), 
		preload("res://addons/Turn_Based_System/assets/icons/sort.png")
	)

func _exit_tree() -> void:
	remove_custom_type("TurnBasedController")
	remove_custom_type("TurnBasedAgent")
	remove_custom_type("CommandMenu")
	remove_custom_type("TurnOrderBar")
