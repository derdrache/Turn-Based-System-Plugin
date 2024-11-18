extends PanelContainer
class_name CommandMenu
## With it you can setup and select your Commands, Skills or Items in Battle
## To build Commands, you have to setup the mainCommandList with your created Character Resource


signal command_selected(command: Resource)

@export var COMMAND_BUTTON : PackedScene = preload("res://addons/Turn_Based_System/nodes/command_menu/command_button.tscn")

## Setup the main menu [br]
## Array[Dictonary] [br]
## Dictonary Key is the name of the CommandButton [br]
## Diconary Value is the reference of the TurnBasedAgent resource, it can be a single resource or a array of resources [br]
## the Array leads to a second Menu where you can select the resources as commands
@export var mainCommandList: Array[Dictionary] = [
	{"Attack": "basicAttack"},
	{"Skills": "skills"}
]
## test

@onready var main_command_container: VBoxContainer = %MainCommandContainer
@onready var multi_command_container: GridContainer = %MultiCommandContainer

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and multi_command_container.visible:
		multi_command_container.hide()
		main_command_container.show()
		
		main_command_container.get_children()[0].grab_focus()

func _ready() -> void:
	add_to_group("commandMenu")
	
	hide()
	
	_set_late_signals()

func _on_command_pressed(commandResource: Resource):
	hide()

	command_selected.emit(commandResource)
	
	main_command_container.show()
	multi_command_container.hide()

func _on_multi_command_button_pressed(commandList: Array[Resource]):
	_clear_multi_command_container()

	_set_multi_command_container(commandList)
	
	main_command_container.hide()
	multi_command_container.show()
	
	await get_tree().process_frame
	await get_tree().process_frame
	## grab_focus needs more then one physicframe to work
	multi_command_container.get_children()[0].grab_focus()

func _clear_multi_command_container():
	for node in multi_command_container.get_children():
		node.queue_free()

func _set_multi_command_container(commandList: Array[Resource]):
	for command in commandList:
		var newCommandButton = COMMAND_BUTTON.instantiate()
		newCommandButton.text = command.name
		newCommandButton.pressed.connect(_on_command_pressed.bind(command))
		multi_command_container.add_child(newCommandButton)

func _on_run_button_pressed():
	get_tree().quit()

func _set_late_signals():
	await get_tree().current_scene.ready
	
	for character: TurnBasedAgent in get_tree().get_nodes_in_group("player"):
		character.player_turn_started.connect(_on_player_turn.bind(character))
		character.undo_command_selected.connect(_on_player_turn.bind(null))

func _on_player_turn(character) -> void:
	if character:
		_reset_main_commands()
		_set_command_options(character)
	
	await get_tree().create_timer(0.01).timeout
	
	show()
	
	if main_command_container.get_children(): 
		main_command_container.get_children()[0].grab_focus()

func _reset_main_commands():
	for node in main_command_container.get_children():
		node.queue_free()

func _set_command_options(character: TurnBasedAgent):
	for mainCommandDict in mainCommandList:
		var mainCommandName = mainCommandDict.keys()[0]
		var mainCommandReference = mainCommandDict[mainCommandDict.keys()[0]]
		var mainCommand = character.character_resource[mainCommandReference]

		var singleCommand = not mainCommand is Array
		var newMainCommandButton = COMMAND_BUTTON.instantiate()
		
		if not mainCommand and mainCommand.is_empty(): continue

		if singleCommand:
			newMainCommandButton.text = mainCommandName
			main_command_container.add_child(newMainCommandButton)
			
			if newMainCommandButton.is_connected("pressed", _on_command_pressed): 
				newMainCommandButton.pressed.disconnect(_on_command_pressed.bind(mainCommand))
			newMainCommandButton.pressed.connect(_on_command_pressed.bind(mainCommand))
		else:
			newMainCommandButton.text = mainCommandName
			main_command_container.add_child(newMainCommandButton)
			newMainCommandButton.pressed.connect(_on_multi_command_button_pressed.bind(mainCommand))
