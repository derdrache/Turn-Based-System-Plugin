extends Node
class_name TurnBasedAgent

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

@onready var on_turn_icon_node: TextureRect = $onTurnIconNode
@onready var target_icon_node: TextureRect = $targetIconNode

@export var character_type: Character_Type

## Character resource should be your resource data where are the stats (health, damage, etc), skills and more are saved
## This is the reference for the command menu
@export var character_resource: Resource

@export var turn_order_value : float

@export_category("Icons")
@export var onTurnIconTexture: CompressedTexture2D
@export var onTurnIconOffSet: Vector2 = Vector2(0,-50)
@export var targetIconTexture: CompressedTexture2D
@export var targetIconOffSet: Vector2 = Vector2(50,0)
@export var turnOrderBarIconTexture: CompressedTexture2D

@export_category("Customize")
@export var selectEnemyIconColor: Color = Color(1,0,0)
@export var selectPlayerIconColor: Color = Color(0, 1, 0)

enum Character_Type {PLAYER, ENEMY, NEUTRAL}

var isActive = false
var mainTarget: TurnBasedAgent
var allSelectedTargets: Array[TurnBasedAgent]
var currentCommand: Resource


func _ready() -> void:
	_set_group()
	
	_set_on_turn_icon()
	_set_target_icon()
	
	_set_late_signals()

func _set_group():	
	add_to_group("turnBasedAgents")
	
	if character_type == Character_Type.PLAYER:
		add_to_group("player")
	elif character_type == Character_Type.ENEMY:
		add_to_group("enemy")
	elif character_type == Character_Type.NEUTRAL:
		add_to_group("neutral")

func _set_on_turn_icon():
	if onTurnIconTexture: on_turn_icon_node.texture = onTurnIconTexture
	
	on_turn_icon_node.hide()
	on_turn_icon_node.global_position = get_parent().global_position - (on_turn_icon_node.get_global_rect().size / 2) + onTurnIconOffSet

func _set_target_icon():
	if targetIconTexture: target_icon_node.texture = targetIconTexture
	
	target_icon_node.hide()
	target_icon_node.global_position = get_parent().global_position - (target_icon_node.get_global_rect().size/2) + targetIconOffSet
	
	if character_type == Character_Type.ENEMY: target_icon_node.modulate = selectEnemyIconColor
	elif character_type == Character_Type.PLAYER: target_icon_node.modulate = selectPlayerIconColor	

func _set_late_signals():
	await get_tree().current_scene.ready
	
	var commandMenu = get_tree().get_first_node_in_group("commandMenu")
	if commandMenu:
		commandMenu.command_selected.connect(_on_command_selected)

func _on_command_selected(command: CommandResource):
	var turnBasedController = get_tree().get_first_node_in_group("turnBasedController")
	if not isActive or turnBasedController.useOwnTargetingSystem: return
	
	currentCommand = command

	var targets: Array
	if command.targetType == CommandResource.Target_Type.ENEMIES:
		targets = get_tree().get_nodes_in_group("enemy")
	elif command.targetType == CommandResource.Target_Type.PLAYERS:
		targets = get_tree().get_nodes_in_group("player")
	
	mainTarget = targets[0]
	
	mainTarget.set_target()
	_check_and_select_multi_target(mainTarget, targets)

func _on_run_command():
	get_tree().quit()

func set_active(boolean: bool):
	isActive = boolean
	
	if isActive: on_turn_icon_node.show()
	else: on_turn_icon_node.hide()
	
	if character_type == Character_Type.PLAYER and isActive: 
		player_turn_started.emit()
	elif character_type == Character_Type.ENEMY and isActive: 
		on_turn_icon_node.hide()
		target_selected.emit(get_tree().get_nodes_in_group("player"), character_resource.basicAttack)
		set_active(false)
	
func set_target():
	target_icon_node.show()

func _deselect_all_targets():
	var allTargets = get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("player")
	
	for target in allTargets:
		target.target_icon_node.hide()	

func _input(event: InputEvent) -> void:
	if not mainTarget: return
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	var players = get_tree().get_nodes_in_group("player")
	
	if mainTarget in enemies: _select_between_targets(event, enemies)
	else: _select_between_targets(event, players)
	
	if event.is_action_pressed("ui_accept"): _select_target()
	elif event.is_action_pressed("ui_cancel"): _undo_command()
	
func _select_between_targets(event: InputEvent, targets: Array):
	var currentTargetIndex = targets.find(mainTarget, 0)
	
	var pressedLeft = event.is_action_pressed("ui_left")
	var pressedRight = event.is_action_pressed("ui_right")
	var pressedUp = event.is_action_pressed("ui_up")
	var pressedDown =  event.is_action_pressed("ui_down")
	
	if pressedLeft or pressedUp:
		currentTargetIndex -= 1
		if currentTargetIndex < 0: currentTargetIndex = targets.size() - 1
	elif pressedRight or pressedDown:
		currentTargetIndex += 1
		if currentTargetIndex > targets.size() - 1: currentTargetIndex = 0
	
	_deselect_all_targets()
	mainTarget = targets[currentTargetIndex]
	mainTarget.set_target()
	
	_check_and_select_multi_target(mainTarget, targets)
	
func _check_and_select_multi_target(mainTarget, targets):
	var targetCount = currentCommand.targetCount
	var mainTargetIndex = targets.find(mainTarget,0)
	var targetSize = targets.size()-1
	
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

func _select_target():
	target_selected.emit(allSelectedTargets, currentCommand)
	_deselect_all_targets()
	set_active(false)
	mainTarget = null
	allSelectedTargets = []
	
func _undo_command():
	mainTarget = null
	_deselect_all_targets()
	allSelectedTargets = []
	undo_command_selected.emit(null)

func command_done():
	turn_finished.emit()

func get_targets():
	return mainTarget

func get_global_position():
	return get_parent().global_position
