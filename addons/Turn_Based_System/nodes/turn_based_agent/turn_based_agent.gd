@tool
extends Node
class_name TurnBasedAgent

## Emitted when a player turn started
signal player_turn_started()
## Emitted when the character has made his  is done
signal turn_finished()
## Emitted when the target selection is canceled
signal undo_command_selected()
## Emitted when the command is selected [br]
## This signal should emitted from the command menu

## Emitted when the target is selected [br]
## Connect to your character to use the selected Command. [br]
## After that use the command_done function the move on
signal target_selected(targets: Array[TurnBasedAgent], command:Resource)
signal target_changed(targets : Array[TurnBasedAgent], allies)

@export var character_type: Character_Type
## Character resource should be your resource data where are the stats (health, damage, etc), skills and more are saved
## This is the reference for the command menu
@export var character_resource: Resource
@export var turnOrderValue : float

@export_category("Icons")
@export var onTurnIconTexture: CompressedTexture2D
@export var onTurnIconOffSet: Vector2 = Vector2(0,-50):
	set(value):
		onTurnIconOffSet = value
		if Engine.is_editor_hint():
			_refresh_on_turn_icon_position()
@export var targetIconTexture: CompressedTexture2D
@export var targetIconOffSet: Vector2 = Vector2(50,0):
	set(value):
		targetIconOffSet = value
		if Engine.is_editor_hint():
			_refresh_target_icon_position()
@export var turnOrderBarIconTexture: CompressedTexture2D

@export_category("Customization")
@export var selectEnemyIconColor: Color = Color(1,0,0)
@export var selectPlayerIconColor: Color = Color(0, 1, 0)

enum Character_Type {PLAYER, ENEMY, NEUTRAL}

const ON_TURON_ICON = preload("res://addons/Turn_Based_System/assets/icons/Icon_Down.png")
const Target_ICON = preload("res://addons/Turn_Based_System/assets/icons/Icon_Left.png")

var onTurnIconNode := TextureRect.new()
var targetIconNode := TextureRect.new()
var isActive := false
var mainTarget: TurnBasedAgent
var allSelectedTargets: Array[TurnBasedAgent]
var currentCommand: Resource
var isTargetAlly := false

func _ready() -> void:
	_set_group()
	
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
		add_to_group("player")
	elif character_type == Character_Type.ENEMY:
		add_to_group("enemy")
	elif character_type == Character_Type.NEUTRAL:
		add_to_group("neutral")

func _create_on_turn_icon() -> void:
	onTurnIconNode.texture = ON_TURON_ICON
	onTurnIconNode.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	onTurnIconNode.custom_minimum_size = Vector2(25,25)
	add_child(onTurnIconNode)
	
	if onTurnIconTexture: onTurnIconNode.texture = onTurnIconTexture
	
	if not Engine.is_editor_hint(): onTurnIconNode.hide()

func _create_target_icon() -> void:
	targetIconNode.texture = Target_ICON
	targetIconNode.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	targetIconNode.custom_minimum_size = Vector2(25,25)
	add_child(targetIconNode)
	
	_refresh_target_icon_position()
	
	if targetIconTexture: targetIconNode.texture = targetIconTexture
	
	_refresh_target_icon_position()
	
	if character_type == Character_Type.ENEMY: targetIconNode.modulate = selectEnemyIconColor
	elif character_type == Character_Type.PLAYER: targetIconNode.modulate = selectPlayerIconColor	

	if not Engine.is_editor_hint(): 
		targetIconNode.hide()

func _refresh_target_icon_position() -> void:
	if not targetIconNode or not get_global_position(): return
	targetIconNode.global_position = get_global_position() - (targetIconNode.get_global_rect().size/2) + targetIconOffSet
	
func _refresh_on_turn_icon_position()-> void:
	if not onTurnIconNode or not get_global_position(): return
	onTurnIconNode.global_position = get_global_position() - (onTurnIconNode.get_global_rect().size / 2) + onTurnIconOffSet


func _set_late_signals() -> void:
	await get_tree().current_scene.ready
	
	var commandMenu = get_tree().get_first_node_in_group("commandMenu")
	if commandMenu:
		commandMenu.command_selected.connect(_on_command_selected)

func _on_command_selected(command: CommandResource) -> void:
	var turnBasedController: TurnBasedController = get_tree().get_first_node_in_group("turnBasedController")
	if not isActive or turnBasedController.useOwnTargetingSystem: return
	
	currentCommand = command

	var targets: Array
	if command.targetType == CommandResource.Target_Type.ENEMIES:
		targets = get_tree().get_nodes_in_group("enemy")
	elif command.targetType == CommandResource.Target_Type.PLAYERS:
		isTargetAlly = true
		targets = get_tree().get_nodes_in_group("player")
	
	mainTarget = targets[0]
	mainTarget.set_target()
	
	_check_and_select_multi_target(mainTarget, targets)
	
	target_changed.emit(allSelectedTargets, isTargetAlly)

func set_active(boolean: bool) -> void:
	isActive = boolean

	if isActive: onTurnIconNode.show()
	else: onTurnIconNode.hide()
	
	if character_type == Character_Type.PLAYER and isActive: 
		player_turn_started.emit()
	elif character_type == Character_Type.ENEMY and isActive: 
		onTurnIconNode.hide()
		target_selected.emit(get_tree().get_nodes_in_group("player"), character_resource.basicAttack)
		set_active(false)
	
func set_target() -> void:
	targetIconNode.show()

func _deselect_all_targets() -> void:
	var allTargets = get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("player")
	
	for target:TurnBasedAgent in allTargets:
		target.targetIconNode.hide()	

func _input(event: InputEvent) -> void:
	if not mainTarget or not event is InputEventKey: return
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	var players = get_tree().get_nodes_in_group("player")
	
	if mainTarget in enemies: _select_between_targets(event, enemies)
	else: _select_between_targets(event, players)
	
	if event.is_action_pressed("ui_accept"): _select_target()
	elif event.is_action_pressed("ui_cancel"): _undo_command()
	
func _select_between_targets(event: InputEvent, targets: Array) -> void:
	var currentTargetIndex: int = targets.find(mainTarget, 0)
	
	var pressedLeft := event.is_action_pressed("ui_left")
	var pressedRight := event.is_action_pressed("ui_right")
	var pressedUp := event.is_action_pressed("ui_up")
	var pressedDown :=  event.is_action_pressed("ui_down")
	
	if pressedLeft or pressedUp:
		currentTargetIndex -= 1
		if currentTargetIndex < 0: currentTargetIndex = targets.size() - 1
	elif pressedRight or pressedDown:
		currentTargetIndex += 1
		if currentTargetIndex > targets.size() - 1: currentTargetIndex = 0
	
	target_changed.emit(allSelectedTargets, isTargetAlly)
	
	_deselect_all_targets()
	
	mainTarget = targets[currentTargetIndex]
	mainTarget.set_target()
	
	_check_and_select_multi_target(mainTarget, targets)
	
func _check_and_select_multi_target(mainTarget: TurnBasedAgent, targets: Array[Node]) -> void:
	var targetCount: int = currentCommand.targetCount
	var mainTargetIndex := targets.find(mainTarget,0)
	var targetSize := targets.size()-1
	
	allSelectedTargets = []
	
	if targetCount == 1: 
		allSelectedTargets.append(mainTarget)
		return
	
	if targetCount > targets.size() or targetCount == -1: targetCount = targetSize

	for i in targetCount:
		targets[mainTargetIndex].set_target()
		allSelectedTargets.append(targets[mainTargetIndex])
		
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

func set_turn_order_value(value: int) -> void:
	turnOrderValue = value
	
func get_turn_order_value() -> float:
	return turnOrderValue
