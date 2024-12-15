@tool
extends PanelContainer
## With it you can setup and select your Commands, Skills or Items in Battle
## To build Commands, you have to setup the mainCommandList with your created Character Resource

signal command_selected(command: Resource)

@export var withButtonIcons := false:
	set(value):
		withButtonIcons = value
		notify_property_list_changed()

@export_group("Main Menu")
## Name of the Command Buttons on the Main Menu [br]
## This list controls the size of the other lists in this group
@export var mainCommandButtonNames: Array[String] = ["Attack"]:
	set(value):
		mainCommandButtonNames = value
		
		var newSize = mainCommandButtonNames.size()
		mainCommandButtonReference.resize(newSize)
		mainCommandIcons.resize(newSize)
		
		_editor_command_menu_refresh()
## Put in the reference variable of the character resource for the commands
@export var mainCommandButtonReference: Array[String] = []:
	set(value):
		mainCommandButtonReference = _get_allowed_size(value, mainCommandButtonNames)
		
		_editor_command_menu_refresh()
## Add a Icon for the CommandButton. [br]
## It appears to the left of the text
@export var mainCommandIcons: Array[CompressedTexture2D]:
	set(value):
		mainCommandIcons = _get_allowed_size(value, mainCommandButtonNames)
		
		_editor_command_menu_refresh()
## Add custom CommandButtons [br]
## if you want a press function that doesn't go trough character, this is your way
@export var ownCommandMain: Array[PackedScene]:
	set(value):
		ownCommandMain = value
		_editor_command_menu_refresh()

@export_group("Left Menu")
@export var withLeftMenu := false:
	set(value):
		withLeftMenu = value
		notify_property_list_changed()
@export var leftCommandButtonNames: Array[String] = []:
	set(value):
		leftCommandButtonNames = value
		
		var newSize = leftCommandButtonNames.size()
		leftCommandButtonReference.resize(newSize)
		leftCommandIcons.resize(newSize)
@export var leftCommandButtonReference: Array[String] = []:
	set(value):
		leftCommandButtonReference = _get_allowed_size(value, leftCommandButtonNames)
@export var leftCommandIcons: Array[CompressedTexture2D] = []:
	set(value):
		leftCommandIcons = _get_allowed_size(value, leftCommandButtonNames)
@export var ownCommandLeft: Array[PackedScene] = []

@export_group("Right Menu")
@export var withRightMenu := false:
	set(value):
		withRightMenu = value
		notify_property_list_changed()
@export var rightCommandButtonNames: Array[String] = []:
	set(value):
		rightCommandButtonNames = value
		
		var newSize = rightCommandButtonNames.size()
		rightCommandButtonReference.resize(newSize)
		rightCommandIcons.resize(newSize)
@export var rightCommandButtonReference: Array[String] = []:
	set(value):
		rightCommandButtonReference = _get_allowed_size(value, rightCommandButtonNames)
@export var rightCommandIcons: Array[CompressedTexture2D] = []:
	set(value): 
		rightCommandIcons = _get_allowed_size(value, rightCommandButtonNames)
@export var ownCommandRight: Array[PackedScene] = []


@onready var main_command_container: VBoxContainer = %MainCommandContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var multi_command_container: GridContainer = %MultiCommandContainer

const COMMAND_BUTTON = preload("res://addons/Turn_Based_System/scenes/classic_command_menu/classic_command_button.tscn")
const COMMAND_RESOURCE = preload("res://addons/Turn_Based_System/resources/command_resource.gd")

var commandCanceled := false
var menuIndex = 1
var currentCharacter: TurnBasedAgent

func _input(event: InputEvent) -> void:	
	if visible:
		if event.is_action_pressed("ui_cancel"):
			scroll_container.hide()
			main_command_container.show()
			main_command_container.get_children()[0].grab_focus()
		elif event.is_action_pressed("ui_left"):
			_change_menu_index(-1)
		elif event.is_action_pressed("ui_right"):
			_change_menu_index(1)
	else:
		if event.is_action_pressed("ui_cancel"):
			commandCanceled = true	

func _change_menu_index(changeValue: int):
	var oldValue = menuIndex
	menuIndex += changeValue
	
	var minValue = 1
	var maxValue = 1
	
	if withLeftMenu:
		minValue = 0
	
	if withRightMenu:
		maxValue = 2
	
	menuIndex = clamp(menuIndex, minValue, maxValue)
	
	if oldValue == menuIndex: return 
	
	_reset_command_menu()
	_refresh_main_command_menu()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	main_command_container.get_children()[0].grab_focus()
	

func _ready() -> void:
	add_to_group("turnBasedCommandMenu")
	
	_editor_command_menu_refresh()

	if not Engine.is_editor_hint(): 
		if mainCommandButtonNames.is_empty():
			push_warning("no mainCommandButtonNames set")
			
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
		character.undo_command_selected.connect(_on_player_turn.bind(character))

func _on_player_turn(character: TurnBasedAgent) -> void:
	currentCharacter = character
	
	if not character.commandNames.is_empty(): 
		mainCommandButtonNames = character.commandNames
	if not character.commandButtonReference.is_empty(): 
		mainCommandButtonReference = character.commandReference
	
	_reset_main_commands()
	_refresh_main_command_menu()

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

func _refresh_main_command_menu() -> void:
	var menuData = _get_menu_data()

	for button in menuData["ownButtons"]:
		if button == null: continue
		
		var newButton = button.instantiate()
		newButton.buttonIcon = menuData["icons"][menuData["names"].size() - 1 + menuData["ownButtons"].find(button)]
		
		main_command_container.add_child(newButton)

	for commandName: String in menuData["names"]:
		var index = menuData["names"].find(commandName)
		var commandReference = menuData["references"][index]
		var commandResource
		
		if commandName.is_empty(): commandName = " "
		
		if currentCharacter.character_resource and commandReference in currentCharacter.character_resource:
			commandResource = currentCharacter.character_resource[commandReference]
		else:
			if not currentCharacter.character_resource:
				push_error("TurnBasedAgent from " + str(currentCharacter.get_parent()) + " doesn't have set: character.character_resource ")
			else:
				push_warning("MainCommandList: " + commandName + " doenst have a reference in character resource")
		
			if index == 0 && menuIndex == 1:
				commandResource = COMMAND_RESOURCE.new()
				commandResource.name = "Attack"
				commandResource.targetType = CommandResource.Target_Type.ENEMIES
		
		var isSingleCommand = not commandResource is Array
		
		var newMainCommandButton = COMMAND_BUTTON.instantiate()
		newMainCommandButton.text = commandName
		newMainCommandButton.buttonIcon = menuData["icons"][index]
		if not commandResource: newMainCommandButton.focus_mode = Control.FOCUS_NONE
		main_command_container.add_child(newMainCommandButton)
		
		if isSingleCommand:
			newMainCommandButton.pressed.connect(_on_command_pressed.bind(commandResource))
		else:
			newMainCommandButton.pressed.connect(_on_multi_command_button_pressed.bind(commandResource))
	
		
func _get_menu_data() -> Dictionary:
	match menuIndex:
		0: return {
				"names": leftCommandButtonNames,
				"references": leftCommandButtonReference,
				"icons": leftCommandIcons,
				"ownButtons": ownCommandLeft
			}
		1: return {
				"names": mainCommandButtonNames,
				"references": mainCommandButtonReference,
				"icons": mainCommandIcons,
				"ownButtons": ownCommandMain
			}
		2: return {
				"names": rightCommandButtonNames,
				"references": rightCommandButtonReference,
				"icons": rightCommandIcons,
				"ownButtons": ownCommandRight
			}
		_: return {}

func _reset_command_menu() -> void:
	for node in main_command_container.get_children():
		node.queue_free()

## dynamic inspector
func _validate_property(property: Dictionary):
	var hideList = []
	
	if not withButtonIcons:
		hideList.append("mainCommandIcons")
		
	if not withLeftMenu:
		hideList.append("leftCommandButtonNames")
		hideList.append("leftCommandButtonReference")
		hideList.append("leftCommandIcons")
		hideList.append("ownCommandLeft")
	elif not withButtonIcons:
		hideList.append("leftCommandIcons")
		
	if not withRightMenu:
		hideList.append("rightCommandButtonNames")
		hideList.append("rightCommandButtonReference")
		hideList.append("rightCommandIcons")
		hideList.append("ownCommandRight")
	elif not withButtonIcons:
		hideList.append("rightCommandIcons")
	
	if property.name in hideList: 
		property.usage = PROPERTY_USAGE_NO_EDITOR 

func _editor_command_menu_refresh():
	if not Engine.is_editor_hint(): return
	
	_reset_main_commands()
	
	for i in mainCommandButtonNames.size():
		var newMainCommandButton = COMMAND_BUTTON.instantiate()
		newMainCommandButton.text = mainCommandButtonNames[i]
		newMainCommandButton.buttonIcon = mainCommandIcons[i]
		main_command_container.add_child(newMainCommandButton)

func _get_allowed_size(value: Array, matchArray: Array):
	var arraySize = matchArray.size()
	
	if value.size() !=  arraySize:
		value.resize(arraySize)
		
	return value

	
	
