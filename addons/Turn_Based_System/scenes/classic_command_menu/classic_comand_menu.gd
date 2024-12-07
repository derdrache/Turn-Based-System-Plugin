@tool
extends PanelContainer
## With it you can setup and select your Commands, Skills or Items in Battle
## To build Commands, you have to setup the mainCommandList with your created Character Resource

signal command_selected(command: Resource)

@export_category("Main Command Buttons")

## Name of the Command Buttons on the Main Menu [br]
## This list controls the size of the other lists in this group
@export var mainCommandButtonNames: Array[String] = ["Attack"]:
	set(value):
		mainCommandButtonNames = value
		var newSize = mainCommandButtonNames.size()
		mainCommandIcons.resize(newSize)
		mainCommandButtonReference.resize(newSize)
		
		if not Engine.is_editor_hint(): return
		
		_reset_main_commands()
		_set_command_options()

## Put in the reference variable of the character resource for the commands
@export var mainCommandButtonReference: Array[String] = []:
	set(value):
		var arraySize = mainCommandButtonNames.size()
		
		if value.size() == arraySize:
			mainCommandButtonReference = value
		elif value.is_empty():
			value.resize(arraySize)
			mainCommandButtonReference = value

		if not Engine.is_editor_hint(): return
		_reset_main_commands()
		_set_command_options()

@export var withButtonIcons := false:
	set(value):
		withButtonIcons = value
		notify_property_list_changed()
		
## Add a Icon for the CommandButton. [br]
## It appears to the left of the text
@export var mainCommandIcons: Array[CompressedTexture2D]:
	set(value):
		if value.is_empty():
			var arraySize = mainCommandButtonNames.size()
			value.resize(arraySize)
			mainCommandIcons = value
			
		mainCommandIcons = value
		
		if not Engine.is_editor_hint(): return
		_reset_main_commands()
		_set_command_options()

@export_category("Own Command Buttons")
## Add custom CommandButtons [br]
## if you want a press function that doesn't go trough character, this is your way
@export var extraMainCommands: Array[PackedScene]:
	set(value):
		extraMainCommands = value
		var newSize = mainCommandButtonNames.size() + extraMainCommands.size()
		mainCommandIcons.resize(newSize)
		mainCommandButtonReference.resize(newSize)
		
		if not Engine.is_editor_hint(): return
		
		_reset_main_commands()
		_set_command_options()	
		
@onready var main_command_container: VBoxContainer = %MainCommandContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var multi_command_container: GridContainer = %MultiCommandContainer

const COMMAND_BUTTON = preload("res://addons/Turn_Based_System/scenes/classic_command_menu/classic_command_button.tscn")
const COMMAND_RESOURCE = preload("res://addons/Turn_Based_System/resources/command_resource.gd")

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
	
	_set_command_options()

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
	
	for commandName: String in mainCommandButtonNames:
		var index = mainCommandButtonNames.find(commandName)
		
		#if mainCommandDict.keys().is_empty(): 
			#if not Engine.is_editor_hint():
				#var index = mainCommandList.find(mainCommandDict)
				#push_warning("entry "+str(index) + " in mainCommandList is empty")
			#continue
		var commandReference = mainCommandButtonReference[index]
		var mainCommand = null
		
		if character: 
			if commandReference in character.character_resource:
				mainCommand = character.character_resource[commandReference]
			else:
				var commandResource: CommandResource = COMMAND_RESOURCE.new()
				commandResource.name = "Attack"
				commandResource.targetType = CommandResource.Target_Type.ENEMIES	
				mainCommand = commandResource	
		else: 
			if not Engine.is_editor_hint():
				push_warning("MainCommandList: " + commandName + " doenst have a reference in character resource")
		
		var singleCommand = not mainCommand is Array
		var newMainCommandButton = COMMAND_BUTTON.instantiate()
		newMainCommandButton.buttonIcon = mainCommandIcons[index]
		
		if not singleCommand and mainCommand.is_empty(): continue
		
		if singleCommand:
			newMainCommandButton.text = commandName
			main_command_container.add_child(newMainCommandButton)
			
			if index > 0 && not commandReference: continue
			
			if newMainCommandButton.is_connected("pressed", _on_command_pressed): 
				newMainCommandButton.pressed.disconnect(_on_command_pressed.bind(mainCommand))
			newMainCommandButton.pressed.connect(_on_command_pressed.bind(mainCommand))
		else:
			newMainCommandButton.text = commandName
			main_command_container.add_child(newMainCommandButton)
			newMainCommandButton.pressed.connect(_on_multi_command_button_pressed.bind(mainCommand))

		if index == 0 and not Engine.is_editor_hint(): 
			newMainCommandButton.grab_focus()
		
			
	for button in extraMainCommands:
		var newButton = button.instantiate()
		newButton.buttonIcon = mainCommandIcons[mainCommandButtonNames.size() - 1 + extraMainCommands.find(button)]
		
		main_command_container.add_child(newButton)	

func _check_resource_setup(character):
	if not character.character_resource: 
		push_error("TurnBasedAgent from " + str(character.get_parent()) + " doesn't have set: character.character_resource ")
		return


## dynamic inspector
func _validate_property(property: Dictionary):
	var hideList = []
	
	if not withButtonIcons:
		hideList.append("mainCommandIcons")
	
	if property.name in hideList: 
		property.usage = PROPERTY_USAGE_NO_EDITOR 
