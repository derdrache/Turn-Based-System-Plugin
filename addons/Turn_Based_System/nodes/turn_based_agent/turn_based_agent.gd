@tool
extends Node
class_name TurnBasedAgent

## Emitted when a player turn started
signal player_turn_started()

## Emitted when the character has used his command [br]
## For this you have to use command_done
signal turn_finished()

## Emitted when the target selection is canceled
signal undo_command_selected()

## Emitted when the target is selected [br]
## Connect to your character to use the selected Command. [br]
## After that use the command_done function the move on
signal target_selected(targets: Array[TurnBasedAgent], command:Resource)
signal target_changed(targets : Array[TurnBasedAgent], allies)

## Important setting
@export var character_type: Character_Type:
	set(value):
		character_type = value
		notify_property_list_changed()
## Character resource should be your resource data where are the stats (health, damage, etc), skills and more are saved
## This is the reference for the command menu
@export var character_resource: Resource
## the name of the variable in the character resource that is to determine the turnorder
## example: speed
@export var turnOrderValueName : String

@export_category("Icons")
## Indication icon if the character is on turn [br]
@export var onTurnIconTexture: CompressedTexture2D
@export var onTurnIconOffSet: Vector3 = Vector3.ZERO:
	set(value):
		onTurnIconOffSet = value
		if Engine.is_editor_hint():
			_refresh_on_turn_icon_position()
@export var targetIconTexture: CompressedTexture2D
@export var targetIconOffSet: Vector3 = Vector3.ZERO:
	set(value):
		targetIconOffSet = value
		if Engine.is_editor_hint():
			_refresh_target_icon_position()
		
@export var turnOrderBarIconTexture: CompressedTexture2D

@export_category("Customization")
@export var selectEnemyIconColor: Color = Color(1,0,0)
@export var selectPlayerIconColor: Color = Color(0, 1, 0)

enum Character_Type {
	## Controllable friendly unit
	PLAYER, 
	## Non-controllable enemy unit
	ENEMY
	}

const ON_TURON_ICON = preload("res://addons/Turn_Based_System/assets/icons/Icon_Down.png")
const Target_ICON = preload("res://addons/Turn_Based_System/assets/icons/Icon_Left.png")

var is3DScene: bool
var onTurnIconNode
var targetIconNode
var isActive := false
var possibleTargets: Array
var mainTarget: TurnBasedAgent
var allSelectedTargets: Array[TurnBasedAgent]
var currentCommand: Resource
var isTargetAlly := false

func _ready() -> void:
	_set_group()
	
	is3DScene = get_parent() is Node3D
	
	_create_on_turn_icon()
	_create_target_icon()
	
	if not Engine.is_editor_hint():
		_set_late_signals()
		
func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	_refresh_on_turn_icon_position()

func _set_group() -> void:
	add_to_group("turnBasedAgents")
	
	if character_type == Character_Type.PLAYER:
		add_to_group("turnBasedPlayer")
	elif character_type == Character_Type.ENEMY:
		add_to_group("turnBasedEnemy")

func _create_on_turn_icon() -> void:	
	if is3DScene:
		onTurnIconNode = Sprite3D.new()
		onTurnIconNode.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		onTurnIconNode.scale *= 0.5
	else:
		onTurnIconNode = TextureRect.new()
		onTurnIconNode.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		onTurnIconNode.custom_minimum_size = Vector2(25,25)
	
	onTurnIconNode.texture = ON_TURON_ICON

	add_child(onTurnIconNode)
	
	if onTurnIconTexture: onTurnIconNode.texture = onTurnIconTexture
	
	if not Engine.is_editor_hint(): onTurnIconNode.hide()

func _create_target_icon() -> void:
	if is3DScene:
		targetIconNode = Sprite3D.new()
		targetIconNode.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		targetIconNode.scale *= 0.5
	else:
		targetIconNode = TextureRect.new()
		targetIconNode.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		targetIconNode.custom_minimum_size = Vector2(25,25)
	
	targetIconNode.texture = Target_ICON
	
	add_child(targetIconNode)
	
	if targetIconTexture: targetIconNode.texture = targetIconTexture
	
	if character_type == Character_Type.ENEMY: targetIconNode.modulate = selectEnemyIconColor
	elif character_type == Character_Type.PLAYER: targetIconNode.modulate = selectPlayerIconColor	

	if not Engine.is_editor_hint(): 
		targetIconNode.hide()
		
	_refresh_target_icon_position()

func _refresh_target_icon_position() -> void:
	if not targetIconNode or not get_global_position(): return
	
	if is3DScene: 
		targetIconNode.global_position = get_global_position() +  targetIconOffSet
	else:
		targetIconNode.global_position = get_global_position() + Vector2(targetIconOffSet.x, targetIconOffSet.y)

func _refresh_on_turn_icon_position()-> void:
	if not onTurnIconNode or not get_global_position(): return
	
	if is3DScene: 
		onTurnIconNode.global_position = get_global_position() + onTurnIconOffSet
	else:
		onTurnIconNode.global_position = get_global_position() + Vector2(onTurnIconOffSet.x, onTurnIconOffSet.y)

func _set_late_signals() -> void:
	await get_tree().current_scene.ready
	
	var commandMenu = get_tree().get_first_node_in_group("turnBasedCommandMenu")
	if commandMenu:
		commandMenu.command_selected.connect(_on_command_selected)


func _on_command_selected(command: CommandResource) -> void:
	var turnBasedController: TurnBasedController = get_tree().get_first_node_in_group("turnBasedController")
	if not isActive or turnBasedController.useOwnTargetingSystem: return
	
	currentCommand = command

	match command.targetType:
		CommandResource.Target_Type.ENEMIES:
			possibleTargets = get_tree().get_nodes_in_group("turnBasedEnemy")
		CommandResource.Target_Type.PLAYERS:
			isTargetAlly = true
			possibleTargets = get_tree().get_nodes_in_group("turnBasedPlayer")
		CommandResource.Target_Type.SELF:
			isTargetAlly = true
			possibleTargets = [self]
	
	mainTarget = possibleTargets[0]
	mainTarget.set_target()
	
	_check_and_select_multi_target(mainTarget, possibleTargets)
	
	target_changed.emit(allSelectedTargets, isTargetAlly)

func set_active(boolean: bool) -> void:
	isActive = boolean

	if isActive: onTurnIconNode.show()
	else: onTurnIconNode.hide()
	
	if character_type == Character_Type.PLAYER and isActive: 
		player_turn_started.emit()
	elif character_type == Character_Type.ENEMY and isActive: 
		onTurnIconNode.hide()
		target_selected.emit(get_tree().get_nodes_in_group("turnBasedPlayer"), character_resource.basicAttack)
		set_active(false)
	
func set_target() -> void:
	targetIconNode.show()

func _deselect_all_targets() -> void:
	var allTargets = get_tree().get_nodes_in_group("turnBasedEnemy") + get_tree().get_nodes_in_group("turnBasedPlayer")
	
	for target:TurnBasedAgent in allTargets:
		target.targetIconNode.hide()	

func _input(event: InputEvent) -> void:
	if not mainTarget or not event is InputEventKey: return
	
	_select_between_targets(event)
	
	if event.is_action_pressed("ui_accept"): _select_target()
	elif event.is_action_pressed("ui_cancel"): _undo_command()
	
func _select_between_targets(event: InputEvent) -> void:
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
	
	target_changed.emit(allSelectedTargets, isTargetAlly)
	
	_deselect_all_targets()
	
	mainTarget = possibleTargets[currentTargetIndex]
	mainTarget.set_target()
	
	_check_and_select_multi_target(mainTarget, possibleTargets)
	
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
	target_selected.emit(allSelectedTargets, currentCommand)
	_deselect_all_targets()
	set_active(false)
	mainTarget = null
	allSelectedTargets = []
	
func _undo_command() -> void:
	mainTarget = null
	_deselect_all_targets()
	allSelectedTargets = []
	undo_command_selected.emit()

func command_done() -> void:
	turn_finished.emit()

func get_targets() -> TurnBasedAgent:
	return mainTarget

func get_global_position():
	if not get_parent() or get_parent() is SubViewport: return
	return get_parent().global_position
	
func get_turn_order_value() -> float:
	if not turnOrderValueName and not Engine.is_editor_hint(): 
		push_warning("No turnOrderValueName set in the agend from: " + str(get_parent()))
		return 0
	
	return character_resource[turnOrderValueName]

func _validate_property(property: Dictionary):
	var hideList = []
	
	if character_type == Character_Type.ENEMY: 
		hideList.append("onTurnIconTexture")
		hideList.append("onTurnIconOffSet")
		hideList.append("selectEnemyIconColor")
		hideList.append("selectPlayerIconColor")
	
	if property.name in hideList: 
		property.usage = PROPERTY_USAGE_NO_EDITOR 
