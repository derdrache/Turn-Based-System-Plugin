extends Control

@export var playerBackgroundColor := Color(0,1,0)
@export var enemyBackgroundColor := Color(1,0,0)

@onready var character_container: VBoxContainer = %CharacterContainer

const CHARACTER_DISPLAY = preload("res://addons/turn_based_battle/nodes/turn_order_bar/character_display.tscn")

var characterTurnOrder: Array[TurnBasedAgent]

func _ready() -> void:
	_set_signals()
	
	_refresh_bar()
	
func _clear_data():
	for child in character_container.get_children():
		child.queue_free()

func _set_signals():
	var turnBasedController: TurnBasedController = get_tree().get_first_node_in_group("turnBasedController")
	if turnBasedController:
		turnBasedController.turn_order_changed.connect(_on_turn_order_changed)

func _on_turn_order_changed(newCharacterOrder : Array[TurnBasedAgent]):
	characterTurnOrder = newCharacterOrder
	_refresh_bar()
	
func _refresh_bar():
	await get_tree().physics_frame # important to avoid a strange delayed update
	
	_clear_data()
	
	for character: TurnBasedAgent in characterTurnOrder:
		var characterDisplayNode = CHARACTER_DISPLAY.instantiate()
		characterDisplayNode.icon = character.turnOrderBarIconTexture
		#characterDisplayNode.characterName = character.get_parent().name
		
		var styleBox = characterDisplayNode.get_theme_stylebox("panel").duplicate()
		if character.character_type == TurnBasedAgent.Character_Type.PLAYER:
			styleBox.bg_color = playerBackgroundColor
		elif character.character_type == TurnBasedAgent.Character_Type.ENEMY:
			styleBox.bg_color = enemyBackgroundColor
		characterDisplayNode.add_theme_stylebox_override("panel", styleBox)
		
		character_container.add_child(characterDisplayNode)
		
	
