@icon("res://addons/Turn_Based_System/assets/icons/sort.png")
extends Control
class_name TurnOrderBar

@export var showTargets := true
@export var scrollable := true

@export_category("Customization")
@export var onTurnIcon: CompressedTexture2D
@export var targetIcon: CompressedTexture2D
@export var playerBackgroundColor := Color(0,1,0)
@export var enemyBackgroundColor := Color(1,0,0)
@export var onTurnColor := Color.YELLOW
@export var allyTargetColor := Color.GREEN
@export var enemyTargetColor := Color.RED

@onready var character_container: VBoxContainer = %CharacterContainer
@onready var target_icons_container: Control = %TargetIconsContainer
@onready var on_turn_icon_texture_rect: TextureRect = $onTurnIconTextureRect
@onready var scroll_container: ScrollContainer = %ScrollContainer

const CHARACTER_DISPLAY = preload("res://addons/Turn_Based_System/scenes/classic/classic_turn_order_bar/character_display.tscn")
const ON_TURN_ICON = preload("res://addons/Turn_Based_System/scenes/classic/classic_turn_order_bar/on_turn_icon.tscn")

var characterTurnOrder: Array[TurnBasedAgent]
var targetOffSet := Vector2(-50, 10)
var onTurnNodeOffSet := Vector2(70, 10)
var currentTargets: Array[TurnBasedAgent]
var isCurrentTargetAlly: bool

func _ready() -> void:
	_setup_on_turn_icon()
		
	_setup_signals()
		
	_setup_late_signals()
		
	_refresh_bar()	
	
func _setup_on_turn_icon() -> void:
	if onTurnIcon: on_turn_icon_texture_rect.texture = onTurnIcon
	on_turn_icon_texture_rect.modulate = onTurnColor
	
func _clear_data() -> void:
	for child in character_container.get_children():
		child.queue_free()

func _setup_signals() -> void:
	var turnBasedController: TurnBasedController = get_tree().get_first_node_in_group("turnBasedController")
	if turnBasedController:
		turnBasedController.turn_order_changed.connect(_on_turn_order_changed)
		
func _setup_late_signals() -> void:
	await get_tree().current_scene.ready
	
	var allCharacters = get_tree().get_nodes_in_group("turnBasedAgents")
	
	for character: TurnBasedAgent in allCharacters:
		character.target_changed.connect(_on_target_changed)
		character.undo_command_selected.connect(_on_command_undo)
		character.player_turn_started.connect(func (): show())
		character.player_action_started.connect(func (_targets, _command): hide())

func _on_target_changed(targets: Array[TurnBasedAgent], isTargetAlly: bool)-> void:
	_set_target_nodes(targets, isTargetAlly)

func _on_command_undo() -> void:
	currentTargets = []
	
	remove_all_target_nodes()


func _set_target_nodes(targets: Array[TurnBasedAgent], isTargetAlly: bool) -> void:
	if targets.is_empty() or not showTargets : return
	
	currentTargets = targets
	isCurrentTargetAlly = isTargetAlly

	remove_all_target_nodes()

	if targets.size() == 1: 
		_create_target_node(targets[0], isTargetAlly)
	else:
		for target:TurnBasedAgent in targets:
			_create_target_node(target, isTargetAlly)

func _create_target_node(target, isTargetAlly) -> void:
	var turnBasedController: TurnBasedController = get_tree().get_first_node_in_group("turnBasedController")
	var isDynamicType = turnBasedController.turnOrderType  == turnBasedController.Turn_Order_Type.DYNAMIC
	
	if not isDynamicType: return
	
	var index: int = characterTurnOrder.find(target)
	var targetNode = ON_TURN_ICON.instantiate()
	
	if targetIcon: targetNode.texture = targetIcon
	if isTargetAlly: targetNode.modulate = allyTargetColor
	else: targetNode.modulate = enemyTargetColor
	
	target_icons_container.add_child(targetNode)
	targetNode.global_position = character_container.get_children()[index].global_position + targetOffSet
	
	if targetNode.global_position.y < scroll_container.global_position.y: targetNode.hide()

func remove_all_target_nodes() -> void:
	for node in target_icons_container.get_children():
		node.queue_free()
	
func _on_turn_order_changed(newCharacterOrder : Array[TurnBasedAgent]) -> void: 
	remove_all_target_nodes()
	currentTargets = []
	characterTurnOrder = newCharacterOrder
	_refresh_bar()
	
func _refresh_bar() -> void:
	await get_tree().physics_frame # important to avoid a strange delayed update
	
	_clear_data()
	
	for character: TurnBasedAgent in characterTurnOrder:
		var characterDisplayNode := CHARACTER_DISPLAY.instantiate()
		characterDisplayNode.icon = character.turnOrderBarIconTexture
		
		var styleBox: StyleBox = characterDisplayNode.get_theme_stylebox("panel").duplicate()
		if character.character_type == TurnBasedAgent.Character_Type.PLAYER:
			styleBox.bg_color = playerBackgroundColor
		elif character.character_type == TurnBasedAgent.Character_Type.ENEMY:
			styleBox.bg_color = enemyBackgroundColor
		characterDisplayNode.add_theme_stylebox_override("panel", styleBox)
		
		character_container.add_child(characterDisplayNode)

func _input(event: InputEvent) -> void:
	_scroll_bar(event)
	
func _scroll_bar(event) -> void:
	var isMouseOver := get_global_rect().has_point(get_global_mouse_position())
	if not isMouseOver or not scroll_container or not scrollable: return
	
	if not event is InputEventMouseButton: return
	
	var mouseWheelUp: bool = event.button_index == 4
	var mouseWheelDown: bool = event.button_index == 5
	
	if mouseWheelDown: scroll_container.scroll_vertical += 20
	elif mouseWheelUp: scroll_container.scroll_vertical -= 20		

	_change_icons_position()

func _change_icons_position() -> void:
	await get_tree().create_timer(0.01).timeout
	
	if currentTargets: _set_target_nodes(currentTargets, isCurrentTargetAlly)
	
	on_turn_icon_texture_rect.global_position.y = character_container.get_children()[0].global_position.y + onTurnNodeOffSet.y
	if on_turn_icon_texture_rect.global_position.y < scroll_container.global_position.y: on_turn_icon_texture_rect.hide()
	else: on_turn_icon_texture_rect.show()
		
