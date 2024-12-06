@tool
extends PanelContainer
## With it you can setup and select your Commands, Skills or Items in Battle
## To build Commands, you have to setup the mainCommandList with your created Character Resource

signal command_selected(command: Resource)

@export var COMMAND_BUTTON : PackedScene = preload("res://addons/Turn_Based_System/scenes/classic_command_menu/classic_command_button.tscn")

@export_category("Command Settings")
## Setup the main menu [br]
## Array[Dictonary] [br]
## Dictonary Key is the name of the CommandButton [br]
## Diconary Value is the reference of the TurnBasedAgent resource, it can be a single resource or a array of resources [br]
## the Array leads to a second Menu where you can select the resources as commands
@export var mainCommandList: Array[Dictionary] = [
	{"Attack": "basicAttack"},
	{"Skills": "skills"}
]:
	set(value):
		mainCommandList = value
		var newSize = mainCommandList.size() + extraMainCommands.size()
		mainCommandIcons.resize(newSize)
		mainCommandActions.resize(newSize)
		if not Engine.is_editor_hint(): return
		_reset_main_commands()
		_set_command_options()
## Add a custom CommandButton for a unique press function
@export var extraMainCommands: Array[PackedScene]:
	set(value):
		extraMainCommands = value
		var newSize = mainCommandList.size() + extraMainCommands.size()
		mainCommandIcons.resize(newSize)
		mainCommandActions.resize(newSize)
		if not Engine.is_editor_hint(): return
		_reset_main_commands()
		_set_command_options()	
## Add a Icon for the CommandButton. [br]
## It appears to the left of the text
@export var mainCommandIcons: Array[CompressedTexture2D]:
	set(value):
		var arraySize = mainCommandList.size() + extraMainCommands.size()
		if value.size() == arraySize:
			mainCommandIcons = value
		elif value.is_empty():
			value.resize(arraySize)
			mainCommandIcons = value
		
		if not Engine.is_editor_hint(): return
		_reset_main_commands()
		_set_command_options()
## Add a action to press the button 
@export var mainCommandActions: Array[String]:
	set(value):
		var arraySize = mainCommandList.size() + extraMainCommands.size()
		if value.size() == arraySize:
			mainCommandActions = value
		elif value.is_empty():
			value.resize(arraySize)
			mainCommandActions = value
			
		if not Engine.is_editor_hint(): return
		_reset_main_commands()
		_set_command_options()

@onready var main_command_container: VBoxContainer = %MainCommandContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var multi_command_container: GridContainer = %MultiCommandContainer

var commandCanceled := false

func _input(event: InputEvent) -> void:	
	if event.is_action_pressed("ui_cancel") and visible:
		scroll_container.hide()
		main_command_container.show()
		main_command_container.get_children()[0].grab_focus()
		
	if event.is_action_pressed("ui_cancel") and not visible:
		commandCanceled = true
		
func _ready() -> void:
	add_to_group("turnBasedCommandMenu")
	
	if not Engine.is_editor_hint(): 
		hide()
		_set_late_signals()

func _on_command_pressed(commandResource: Resource) -> void:
	hide()

	command_selected.emit(commandResource)

func _on_multi_command_button_pressed(commandList: Array[Resource]) -> void:
	_clear_multi_command_container()

	_set_multi_command_container(commandList)
	
	main_command_container.hide()
	scroll_container.show()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	multi_command_container.get_children()[0].grab_focus()

func _clear_multi_command_container() -> void:
	for node in multi_command_container.get_children():
		node.queue_free()

func _set_multi_command_container(commandList: Array[Resource]) -> void:
	for command:Resource in commandList:
		var newCommandButton = COMMAND_BUTTON.instantiate()
		newCommandButton.text = command.name
		newCommandButton.pressed.connect(_on_command_pressed.bind(command))
		multi_command_container.add_child(newCommandButton)

func _on_run_button_pressed() -> void:
	get_tree().quit()

func _set_late_signals() -> void:
	await get_tree().current_scene.ready
	
	for character: TurnBasedAgent in get_tree().get_nodes_in_group("turnBasedPlayer"):
		character.player_turn_started.connect(_on_player_turn.bind(character))
		character.undo_command_selected.connect(_on_player_turn.bind(null))

func _on_player_turn(character) -> void:
	if character:
		_check_resource_setup(character)
		_reset_main_commands()
		_set_command_options(character)

	show()
	
	if not commandCanceled: 
		scroll_container.hide()
		main_command_container.show()
		
	# needed for grab_focus
	await get_tree().create_timer(0.01).timeout
	
	if scroll_container.visible:
		multi_command_container.get_children()[0].grab_focus()
	else:
		main_command_container.get_children()[0].grab_focus()

func _reset_main_commands() -> void:
	if not main_command_container: return
	
	for node in main_command_container.get_children():
		node.queue_free()

func _set_command_options(character: TurnBasedAgent = null) -> void:
	if not main_command_container: return
	
	for mainCommandDict: Dictionary in mainCommandList:
		if mainCommandDict.keys().is_empty(): 
			if not Engine.is_editor_hint():
				var index = mainCommandList.find(mainCommandDict)
				push_warning("entry "+str(index) + " in mainCommandList is empty")
			continue
		
		var mainCommandName = mainCommandDict.keys()[0]
		var mainCommandReference = mainCommandDict[mainCommandDict.keys()[0]]
		var mainCommand = null
		
		if character: mainCommand = character.character_resource[mainCommandReference]
		else: 
			if not Engine.is_editor_hint():
				push_warning("MainCommandList: " + mainCommandName + " doenst have a reference in character resource")
		
		var singleCommand = not mainCommand is Array
		var newMainCommandButton = COMMAND_BUTTON.instantiate()
		newMainCommandButton.buttonIcon = mainCommandIcons[mainCommandList.find(mainCommandDict)]
		
		if not singleCommand and mainCommand.is_empty(): continue
		
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
		
		var index = mainCommandList.find(mainCommandDict)
		if index == 0: newMainCommandButton.grab_focus()
		
			
	for button in extraMainCommands:
		var newButton = button.instantiate()
		newButton.buttonIcon = mainCommandIcons[mainCommandList.size() - 1 + extraMainCommands.find(button)]
		
		main_command_container.add_child(newButton)

func _check_resource_setup(character):
	if not character.character_resource: 
		push_error("TurnBasedAgent from " + str(character.get_parent()) + " doesn't have set: character.character_resource ")
		return
