@tool
class_name TurnBasedAgent extends Node

## Emitted when a player turn started
signal player_turn_started()

## Emitted when a enemy turn started
signal enemy_turn_started()

## Emitted when the character has used his command [br]
## For this you have to use command_done
signal turn_finished(agent: TurnBasedAgent)

## Emitted when the target selection is canceled
signal undo_command_selected()

## Emitted when the command can't have a target
## command target_type == NONE
signal command_without_target_selected(command: Resource)

## Emitted when the target is selected [br]
## Connect to your character to use the selected Command. [br]
## After that use the command_done function the move on
signal target_selected(mainTarget: TurnBasedAgent ,targets: Array[TurnBasedAgent], command:Resource)
signal targeting_started(targets: Array[TurnBasedAgent], command:Resource)
signal target_changed(targets : Array[TurnBasedAgent])

## if true, then this character is ignored everywhere.
## e.g. dead
@export var isDisabled := false
## Important setting
@export var character_type: Character_Type:
	set(value):
		character_type = value
		notify_property_list_changed()
## Character resource should be your resource data where are the stats (health, damage, etc), skills and more are saved
## This is the reference for the command menu
@export var characterResource: Resource
## the name of the variable in the character resource that is to determine the turnorder
## example: speed
@export var turnOrderValueName : String
@export var ownMinionGroup: String

@export_group("command_menu")
## Overrides the mainCommandButtonNames in Command Menu
@export var commandNames: Array[String] = []
## Overrides the mainCommandButtonNames in Command Menu
@export var commandButtonReference: Array[String] = []


@export_category("Customize Icons")
@export_group("Turn Icon")
## Indication icon if the character is on turn [br]
@export var onTurnIconTexture: CompressedTexture2D:
	set(value):
		onTurnIconTexture = value
		if value and Engine.is_editor_hint():
			onTurnIconNode = value
@export var onTurnIconOffSet: Vector3 = Vector3.ZERO:
	set(value):
		onTurnIconOffSet = value
		if Engine.is_editor_hint():
			_refresh_on_turn_icon_position()
@export var turnIconScale := 1.0:
	set(value):
		turnIconScale = value
		if value and Engine.is_editor_hint():
			onTurnIconNode.scale = Vector3.ONE * turnIconScale

@export_group("Target Icon")
@export var targetIconTexture: CompressedTexture2D:
	set(value):
		targetIconTexture = value
		if value:
			targetIconNode.texture = value
@export var targetIconOffSet: Vector3 = Vector3.ZERO:
	set(value):
		targetIconOffSet = value
		if Engine.is_editor_hint():
			_refresh_target_icon_position()
@export var targetIconScale := 1.0:
	set(value):
		targetIconScale = value
		if targetIconNode:
			targetIconNode.scale = Vector3.ONE * targetIconScale
@export var selectEnemyIconColor: Color = Color(1,0,0)
@export var selectPlayerIconColor: Color = Color(0, 1, 0)

@export_group("Turn Order Bar Icon")
@export var turnOrderBarIconTexture: CompressedTexture2D

enum Character_Type {
	## Controllable friendly unit
	PLAYER, 
	## Non-controllable enemy unit
	ENEMY,
	## Non-controllable friendly unit
	PASSIV_PLAYER
	}
const ON_TURON_ICON = preload("res://addons/Turn_Based_System/assets/icons/Icon_Down.png")
const Target_ICON = preload("res://addons/Turn_Based_System/assets/icons/Icon_Left.png")

var turnBasedController: TurnBasedController
var is3DScene: bool
var onTurnIconNode
var targetIconNode
var isActive := false
var possibleTargets: Array
var mainTarget: TurnBasedAgent
var allSelectedTargets: Array[TurnBasedAgent]
var currentCommand: Resource
var isTargetAlly := false
var isTargetSelected = false
var atbValue = 0

func _ready() -> void:
	turnBasedController = get_tree().get_first_node_in_group("turnBasedController")
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	atbValue = 0
	
	_set_group()
	
	is3DScene = get_parent() is Node3D
	
	if not characterResource:
		if "characterResource" in get_parent():
			characterResource = get_parent().characterResource

	get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
		
	_create_on_turn_icon()
	_create_target_icon()
	
	if not Engine.is_editor_hint():
		_set_late_signals()

func _set_group() -> void:
	add_to_group("turnBasedAgents")
	
	if character_type == Character_Type.PLAYER:
		add_to_group("turnBasedPlayer")
	elif character_type == Character_Type.ENEMY:
		add_to_group("turnBasedEnemy")
	elif character_type == Character_Type.PASSIV_PLAYER:
		add_to_group("turnBasedPlayerPassiv")

func _create_on_turn_icon() -> void:
	if is3DScene:
		onTurnIconNode = Sprite3D.new()
		onTurnIconNode.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	else:
		onTurnIconNode = TextureRect.new()
		onTurnIconNode.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		onTurnIconNode.custom_minimum_size = Vector2(25,25)
		
	onTurnIconNode.texture = ON_TURON_ICON

	add_child(onTurnIconNode)
	
	if onTurnIconTexture: 
		onTurnIconNode.texture = onTurnIconTexture
	
	if not Engine.is_editor_hint() or character_type == Character_Type.ENEMY: 
		onTurnIconNode.hide()
		
	_refresh_on_turn_icon_position()

func _create_target_icon() -> void:
	if is3DScene:
		targetIconNode = Sprite3D.new()
		targetIconNode.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		onTurnIconNode.scale = Vector3.ONE * targetIconScale
	else:
		targetIconNode = TextureRect.new()
		targetIconNode.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		targetIconNode.custom_minimum_size = Vector2(25,25)
		onTurnIconNode.scale = Vector2.ONE * targetIconScale
	
	targetIconNode.texture = Target_ICON
	
	add_child(targetIconNode)
	
	if targetIconTexture: targetIconNode.texture = targetIconTexture
	
	if character_type == Character_Type.ENEMY: targetIconNode.modulate = selectEnemyIconColor
	elif character_type == Character_Type.PLAYER: targetIconNode.modulate = selectPlayerIconColor	

	if not Engine.is_editor_hint(): 
		targetIconNode.hide()
		
	_refresh_target_icon_position()

func _refresh_target_icon_position() -> void:
	if not targetIconNode: return
	
	if is3DScene: 
		targetIconNode.global_position = get_global_position() +  targetIconOffSet
	else:
		targetIconNode.global_position = get_global_position() + Vector2(targetIconOffSet.x, targetIconOffSet.y)

func _refresh_on_turn_icon_position()-> void:
	if not onTurnIconNode: return
	
	if is3DScene: 
		onTurnIconNode.global_position = get_global_position() + onTurnIconOffSet
	else:
		onTurnIconNode.global_position = get_global_position() + Vector2(onTurnIconOffSet.x, onTurnIconOffSet.y)

func _set_late_signals() -> void:	
	if character_type == Character_Type.PASSIV_PLAYER:
		return
	
	turnBasedController.battle_finished.connect(_on_battle_finished)
	
	if not get_parent().is_node_ready():
		await get_parent().ready
		
	if not get_tree().current_scene.is_node_ready():
		await get_tree().current_scene.ready
	
	var commandMenu = get_tree().get_first_node_in_group("turnBasedCommandMenu")
	if commandMenu:
		commandMenu.command_selected.connect(_on_command_selected)
		
	turnBasedController.new_agent_entered.emit(self)

func _on_battle_finished():
	onTurnIconNode.hide()

func _on_command_selected(command: CommandResource) -> void:
	_refresh_target_icon_position()
	
	if not isActive or turnBasedController.useOwnTargetingSystem: return

	currentCommand = command
	
	if command.targetType == CommandResource.Target_Type.NONE:
		command_without_target_selected.emit(command)
		return

	_set_possible_targets(command)
	
	if possibleTargets.is_empty(): 
		push_warning(command.name + " no possible target")
		_undo_command()
		return
	
	mainTarget = possibleTargets[0]
	mainTarget.set_target()
	
	_check_and_select_multi_target(mainTarget, possibleTargets)

	targeting_started.emit(allSelectedTargets, command)
	target_changed.emit(allSelectedTargets)

func _set_possible_targets(command):
	match command.targetType:
		CommandResource.Target_Type.ENEMIES:
			possibleTargets = get_tree().get_nodes_in_group("turnBasedEnemy")
		CommandResource.Target_Type.PLAYERS, CommandResource.Target_Type.PLAYERS_WITH_DISABLED:
			isTargetAlly = true
			possibleTargets = get_tree().get_nodes_in_group("turnBasedPlayer")
		CommandResource.Target_Type.SELF:
			isTargetAlly = true
			possibleTargets = [self]
		CommandResource.Target_Type.PLAYERS_NOT_SELF:
			isTargetAlly = true
			possibleTargets = get_tree().get_nodes_in_group("turnBasedPlayer")
			possibleTargets.erase(self)
		CommandResource.Target_Type.PLAYERS, CommandResource.Target_Type.PLAYERS_WITH_DISABLED:
			isTargetAlly = true
			possibleTargets = get_tree().get_nodes_in_group(ownMinionGroup)
	
	if not command.targetType == CommandResource.Target_Type.PLAYERS_WITH_DISABLED:
		possibleTargets = possibleTargets.filter(func(target): return not target.isDisabled)

func _deselect_all_targets() -> void:
	var allTargets = get_tree().get_nodes_in_group("turnBasedEnemy") + get_tree().get_nodes_in_group("turnBasedPlayer")
	
	for target:TurnBasedAgent in allTargets:
		target.targetIconNode.hide()	

func _process(delta: float) -> void:
	_handle_atb_value()

func _handle_atb_value():
	if Engine.is_editor_hint() or turnBasedController.manually: return

	var activePlayer = turnBasedController.activeAgent and turnBasedController.withPause
	if activePlayer: return

	if characterResource and turnBasedController.turnOrderType == TurnBasedController.Turn_Order_Type.ATB:
		if atbValue >= 100:
			set_active(true)
		else:
			atbValue += characterResource.speed * turnBasedController.speedFactor

func _input(event: InputEvent) -> void:
	if not mainTarget or not event is InputEventKey or isTargetSelected: return
	
	_select_between_targets(event)
	
	if event.is_action_pressed("ui_accept"): _select_target()
	elif event.is_action_released("ui_cancel"): _undo_command()
	
func _select_between_targets(event: InputEvent) -> void:
	if not event.is_pressed(): return

	var currentTargetIndex: int = possibleTargets.find(mainTarget, 0)
	
	var pressedLeft := event.is_action_pressed("ui_left")
	var pressedRight := event.is_action_pressed("ui_right")
	var pressedUp := event.is_action_pressed("ui_up")
	var pressedDown :=  event.is_action_pressed("ui_down")
	
	if pressedLeft or pressedUp:
		currentTargetIndex -= 1
		if currentTargetIndex < 0: currentTargetIndex = possibleTargets.size() - 1
	elif pressedRight or pressedDown:
		currentTargetIndex += 1
		if currentTargetIndex > possibleTargets.size() - 1: currentTargetIndex = 0
	
	_deselect_all_targets()
	
	mainTarget = possibleTargets[currentTargetIndex]
	mainTarget.set_target()
	
	_check_and_select_multi_target(mainTarget, possibleTargets)
	
	target_changed.emit(allSelectedTargets)
	
func _check_and_select_multi_target(mainTarget: TurnBasedAgent, targets: Array) -> void:
	var targetCount: int = currentCommand.targetCount
	var mainTargetIndex := targets.find(mainTarget,0)
	var targetSize := targets.size()
	
	allSelectedTargets = []
	
	if targetCount == 1: 
		allSelectedTargets.append(mainTarget)
		return
	
	if targetCount > targetSize or targetCount == -1: targetCount = targetSize
	
	for i in targetCount:
		targets[i].set_target()
		allSelectedTargets.append(targets[i])

		mainTargetIndex += 1
		if mainTargetIndex > targetSize: mainTargetIndex = 0		

func _select_target() -> void:
	if isTargetSelected or self != turnBasedController.activeAgent: return
	
	isTargetSelected = true
	target_selected.emit(mainTarget, allSelectedTargets, currentCommand)
	_deselect_all_targets()
	
	onTurnIconNode.hide()
	
	mainTarget = null
	allSelectedTargets = []
	
func _undo_command() -> void: 
	mainTarget = null
	_deselect_all_targets()
	allSelectedTargets = []
	undo_command_selected.emit()
	

# public functions
func add_agent() -> void:
	isDisabled = false
	
	turnBasedController.add_agent(self)

func remove_agent() -> void:
	isDisabled = true
	
	turnBasedController.remove_agent(self)
	
	if isActive:
		turn_finished.emit()

func get_global_position():
	if not get_parent(): return
	
	return get_parent().global_position
	
func get_turn_order_value() -> float:
	if not turnOrderValueName and not Engine.is_editor_hint(): 
		push_warning("No turnOrderValueName set in the agend from: " + str(get_parent()))
		return 0
	
	return characterResource[turnOrderValueName]

func swap_agent(swapAgent: TurnBasedAgent, turnOrderTakeOver = false):
	turnBasedController.swap_agents(self, swapAgent, turnOrderTakeOver)

func command_done() -> void:
	atbValue = 0
	isActive = false
	turn_finished.emit(self)

func set_target() -> void:
	targetIconNode.show()

func set_active(boolean: bool) -> void:
	if boolean and isActive and turnBasedController.activeAgent: return
	
	_refresh_on_turn_icon_position()
	
	isTargetSelected = false
	mainTarget = null
	isActive = boolean

	if isActive: onTurnIconNode.show()
	else: onTurnIconNode.hide()
	
	if character_type == Character_Type.PLAYER and isActive:
		player_turn_started.emit()
	elif character_type == Character_Type.ENEMY and isActive: 
		onTurnIconNode.hide()
		enemy_turn_started.emit()
	
	turnBasedController.activeAgent = self
	
	if turnBasedController.withPause and not Engine.is_editor_hint():
		get_tree().paused = true

func manual_target_selection(targets: Array[TurnBasedAgent]):
	mainTarget = targets[0]
	allSelectedTargets = targets
	_select_target()

func set_disable(boolean: bool):
	isDisabled = boolean
	turnBasedController._refresh_turn_order_bar()

# Editor changes
func _validate_property(property: Dictionary):
	var hideList = []
	
	if character_type == Character_Type.ENEMY: 
		hideList.append("onTurnIconTexture")
		hideList.append("onTurnIconOffSet")
		hideList.append("selectEnemyIconColor")
		hideList.append("selectPlayerIconColor")
	
	if property.name in hideList: 
		property.usage = PROPERTY_USAGE_NO_EDITOR 
