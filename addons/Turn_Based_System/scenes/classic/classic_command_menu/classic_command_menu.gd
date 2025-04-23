@tool
extends PanelContainer
## With it you can setup and select your Commands, Skills or Items in Battle
## To build Commands, you have to setup the mainCommandList with your created Character Resource

signal command_selected(command: Resource)

@export var withButtonIcons := false:
	set(value):
		withButtonIcons = value
		notify_property_list_changed()
		
@export var defaultCommandButton: PackedScene = preload(
	"res://addons/Turn_Based_System/scenes/classic/classic_command_menu/classic_command_button.tscn"):
	set(value):
		defaultCommandButton = value
		_editor_command_menu_refresh()

@export_group("Main Menu")
## Name of the Command Buttons on the Main Menu [br]
## This list controls the size of the other lists in this group
@export var mainCommandButtonNames: Array[String] = ["Attack"]:
	set(value):
		mainCommandButtonNames = value
		
		var newSize = mainCommandButtonNames.size()
		mainCommandButtonReference.resize(newSize)
		mainCommandButtonIcons.resize(newSize)
		
		_editor_command_menu_refresh()
## Put in the reference variable of the character resource for the commands
@export var mainCommandButtonReference: Array[String] = []:
	set(value):
		mainCommandButtonReference = _get_allowed_size(value, mainCommandButtonNames)
		
		_editor_command_menu_refresh()
## Add a Icon for the CommandButton. [br]
## It appears to the left of the text
@export var mainCommandButtonIcons: Array[CompressedTexture2D]:
	set(value):
		mainCommandButtonIcons = _get_allowed_size(value, mainCommandButtonNames)
		
		_editor_command_menu_refresh()
## Add custom CommandButtons [br]
## if you want a press function that doesn't go trough character, this is your way
@export var mainOwnCommandButton: Array[PackedScene]:
	set(value):
		mainOwnCommandButton = value
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
		leftCommandButtonIcons.resize(newSize)
@export var leftCommandButtonReference: Array[String] = []:
	set(value):
		leftCommandButtonReference = _get_allowed_size(value, leftCommandButtonNames)
@export var leftCommandButtonIcons: Array[CompressedTexture2D] = []:
	set(value):
		leftCommandButtonIcons = _get_allowed_size(value, leftCommandButtonNames)
@export var ownCommandButtonLeft: Array[PackedScene] = []

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
		rightCommandButtonIcons.resize(newSize)
@export var rightCommandButtonReference: Array[String] = []:
	set(value):
		rightCommandButtonReference = _get_allowed_size(value, rightCommandButtonNames)
@export var rightCommandButtonIcons: Array[CompressedTexture2D] = []:
	set(value): 
		rightCommandButtonIcons = _get_allowed_size(value, rightCommandButtonNames)
@export var ownCommandButtonRight: Array[PackedScene] = []


@onready var main_command_container: VBoxContainer = %MainCommandContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var multi_command_container: GridContainer = %MultiCommandContainer

const DEFAULT_COMMAND_RESOURCE = preload("res://addons/Turn_Based_System/resources/command_resource.gd")

var commandCanceled := false
var menuIndex = 1
var currentCharacter: TurnBasedAgent

func _input(event: InputEvent) -> void:	
	if not visible: return
	
	if main_command_container.visible:
		if event.is_action_pressed("ui_left"):
			change_menu_index(-1)
		elif event.is_action_pressed("ui_right"):
			change_menu_index(1)
	else:
		if event.is_action_pressed("ui_cancel"):
			scroll_container.hide()
			main_command_container.show()
			main_command_container.get_child(0).call_deferred("grab_focus")

func change_menu_index(changeValue: int):
	var oldValue = menuIndex
	menuIndex += changeValue
	
	var minValue = 1
	var maxValue = 1
	
	if withLeftMenu:
		minValue = 0
	
	if withRightMenu:
		maxValue = 2
	
	menuIndex = clamp(menuIndex, minValue, maxValue)
	
	if oldValue == menuIndex: 
		main_command_container.get_child(0).call_deferred("grab_focus")
		return 
	
	_reset_command_menu()
	_refresh_main_command_menu()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	main_command_container.get_child(0).call_deferred("grab_focus")

func _ready() -> void:
	add_to_group("turnBasedCommandMenu")
	
	_editor_command_menu_refresh()

	if not Engine.is_editor_hint(): 
		if mainCommandButtonNames.is_empty():
			push_warning("no mainCommandButtonNames set")
			
		hide()
		_set_signals()

func _on_command_pressed(commandResource: Resource, button: Button) -> void:
	if not commandResource:
		push_error(button.text + " button doesn't have a reference resource")
		return
		
	var turnBasedController: TurnBasedController = get_tree().get_first_node_in_group("turnBasedController")
	var currentMana = turnBasedController.get_active_character().characterResource.currentMana
	var notEnoughMana = commandResource.manaCost > currentMana
	if not commandResource.isAllowed or notEnoughMana:
		return

	hide()
	
	commandCanceled = false
	
	command_selected.emit(commandResource)

func _on_multi_command_button_pressed(commandList: Array) -> void:
	if commandList.is_empty(): return
	
	_clear_multi_command_container()

	_set_multi_command_container(commandList)
	
	main_command_container.hide()
	scroll_container.show()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	multi_command_container.get_child(0).call_deferred("grab_focus")

func _clear_multi_command_container() -> void:
	for node in multi_command_container.get_children():
		node.queue_free()

func _set_multi_command_container(commandList: Array) -> void:
	for command:Resource in commandList:
		var newCommandButton = defaultCommandButton.instantiate()
		newCommandButton.set_name(command.name)
		newCommandButton.command = command
		newCommandButton.pressed.connect(_on_command_pressed.bind(command, newCommandButton))
		multi_command_container.add_child(newCommandButton)

func _on_run_button_pressed() -> void:
	get_tree().quit()

func _set_signals() -> void:
	for agent: TurnBasedAgent in get_tree().get_nodes_in_group("turnBasedPlayer"):
		_connect_agent_signals(agent)
		
	var turnBasedController = get_tree().get_first_node_in_group("turnBasedController")
	turnBasedController.new_agent_entered.connect(_connect_agent_signals)

func _connect_agent_signals(agent: TurnBasedAgent) -> void:
	agent.player_turn_started.connect(_on_player_turn.bind(agent))
	agent.undo_command_selected.connect(_on_player_turn.bind(agent, true))

func _on_player_turn(character: TurnBasedAgent, commandUndo = false) -> void:
	currentCharacter = character
	commandCanceled = commandUndo
	
	refresh()

func _reset_main_commands() -> void:
	if not main_command_container: return
	
	for node in main_command_container.get_children():
		node.queue_free()

func _refresh_main_command_menu() -> void:
	var menuData = _get_menu_data()

	for button in menuData["ownButtons"]:
		if button == null: continue
		
		var newButton = button.instantiate()
		main_command_container.add_child(newButton)

	for commandName: String in menuData["names"]:
		var index = menuData["names"].find(commandName)
		var isEmpty = commandName.is_empty()
		var commandReference = menuData["references"][index]
		var commandResource
		
		if isEmpty: commandName = " "
		
		if currentCharacter.characterResource and commandReference in currentCharacter.characterResource:
			commandResource = currentCharacter.characterResource[commandReference]
		else:
			if not currentCharacter.characterResource:
				push_error("TurnBasedAgent from " + str(currentCharacter.get_parent()) + " doesn't have set: character.character_resource ")
			else:
				push_warning("MainCommandList: " + commandName + " doenst have a reference in character resource")
			
			if index == 0 && menuIndex == 1:
				commandResource = DEFAULT_COMMAND_RESOURCE.new()
				commandResource.name = "Attack"
				commandResource.targetType = CommandResource.Target_Type.ENEMIES
		
		var isSingleCommand = not commandResource is Array
		
		if not isSingleCommand and commandResource.is_empty():
			push_warning(commandName + " resource are empty. So pressing this button has no effect")
			continue
		
		var newMainCommandButton = defaultCommandButton.instantiate()
		newMainCommandButton.withManaCostLabel = false
		newMainCommandButton.set_name(commandName)
		newMainCommandButton.buttonIcon = menuData["icons"][index]
		if isEmpty: newMainCommandButton.focus_mode = Control.FOCUS_NONE
		main_command_container.add_child(newMainCommandButton)
		
		if isSingleCommand:
			newMainCommandButton.pressed.connect(_on_command_pressed.bind(commandResource, newMainCommandButton))
		else:
			newMainCommandButton.pressed.connect(_on_multi_command_button_pressed.bind(commandResource))

func _get_menu_data() -> Dictionary:
	match menuIndex:
		0: return {
				"names": leftCommandButtonNames,
				"references": leftCommandButtonReference,
				"icons": leftCommandButtonIcons,
				"ownButtons": ownCommandButtonLeft
			}
		1: return {
				"names": mainCommandButtonNames,
				"references": mainCommandButtonReference,
				"icons": mainCommandButtonIcons,
				"ownButtons": mainOwnCommandButton
			}
		2: return {
				"names": rightCommandButtonNames,
				"references": rightCommandButtonReference,
				"icons": rightCommandButtonIcons,
				"ownButtons": ownCommandButtonRight
			}
		_: return {}

func _reset_command_menu() -> void:
	for node in main_command_container.get_children():
		node.queue_free()

func refresh():
	if not currentCharacter.commandNames.is_empty(): 
		mainCommandButtonNames = currentCharacter.commandNames
	if not currentCharacter.commandButtonReference.is_empty(): 
		mainCommandButtonReference = currentCharacter.commandReference
	
	menuIndex = 1
	
	_reset_main_commands()
	_refresh_main_command_menu()

	show()
	
	if commandCanceled:
		var onSkillMenu = scroll_container.visible
		scroll_container.visible = onSkillMenu
		main_command_container.visible = not onSkillMenu
	else:
		scroll_container.hide()
		main_command_container.show()

	# needed for grab_focus
	await get_tree().create_timer(0.01).timeout
	
	if scroll_container.visible:
		multi_command_container.get_child(0).call_deferred("grab_focus")
	else:
		main_command_container.get_child(0).call_deferred("grab_focus")

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

func _editor_command_menu_refresh() -> void:
	if not Engine.is_editor_hint() or not main_command_container: return
	
	_reset_main_commands()
	
	for i in mainCommandButtonNames.size():
		var newMainCommandButton = defaultCommandButton.instantiate()
		newMainCommandButton.text = mainCommandButtonNames[i]
		newMainCommandButton.buttonIcon = mainCommandButtonIcons[i]
		main_command_container.add_child(newMainCommandButton)

func _get_allowed_size(value: Array, matchArray: Array):
	var arraySize = matchArray.size()
	
	if value.size() !=  arraySize:
		value.resize(arraySize)
		
	return value
