class_name TurnBasedController extends Node
## This Node controlls the logic for turn based combat
## It has to stay above your TurnOrderBar

signal round_finished()
signal turn_order_changed(characterTurnOrder)

@export var turnOrderType : Turn_Order_Type
## Nur classic and value_based ?
@export var endlessOrder := false
@export var maxTurnsCalculation := 15

@export_category("targeting system")
@export var useOwnTargetingSystem := false

enum Turn_Order_Type{CLASSIC, VALUE_BASED, DYNAMIC}

var turnOrderList: Array[Dictionary] = []
var activeCharacter: TurnBasedAgent

func _ready() -> void:
	add_to_group("turnBasedController")
	
	await get_tree().create_timer(0.1).timeout
	
	_set_late_signals()

	_set_turn_order()
	
	_set_next_active_character()

func _set_late_signals() -> void:
	for player: TurnBasedAgent in get_tree().get_nodes_in_group("turnBasedAgents"):
		player.turn_finished.connect(_on_turn_done)

func _set_turn_order() -> void:
	var players = get_tree().get_nodes_in_group("player")
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	match turnOrderType:
		Turn_Order_Type.CLASSIC: _set_classic_turn_order(players + enemies)
		Turn_Order_Type.VALUE_BASED: _set_value_based_turn_order(players + enemies)
		Turn_Order_Type.DYNAMIC: _set_dynamic_turn_order(players + enemies)
	
func _set_classic_turn_order(characterList) -> void:
		var rounds := 1
		if endlessOrder: rounds = round(maxTurnsCalculation / (characterList).size())
		
		for i in rounds:
			for character: TurnBasedAgent in characterList:
				turnOrderList.append({
					"node": character
				})
		
func _set_value_based_turn_order(characterList) -> void:
	var rounds := 1
	if endlessOrder: rounds = round(maxTurnsCalculation / (characterList).size())
	
	for i in rounds:
		for character: TurnBasedAgent in characterList:
			turnOrderList.append({
				"node": character,
				"value": character.turn_order_value
			})
		
	turnOrderList.sort_custom(func(a, b): return a.value > b.value)

func _set_dynamic_turn_order(characterList) -> void:
	for character: TurnBasedAgent in characterList:
		var speedValue : float = _get_dynamic_speed_value(character.get_turn_order_value())
		var turnOrderValue : float = 10 - speedValue
		
		while turnOrderValue > 0:
			turnOrderList.append({
							"node": character,
							"value": turnOrderValue
						})
			turnOrderValue -= speedValue

	turnOrderList.sort_custom(func(a, b): return a.value > b.value)
	
func _remove_active_character() -> void:
	if not activeCharacter: return
	
	var lastCharacter := turnOrderList.pop_front()
	var lastCharacterNode : TurnBasedAgent = lastCharacter.node

	if turnOrderType == Turn_Order_Type.DYNAMIC:
		_add_time_to_turn_order(lastCharacter.value - turnOrderList[0].value )
		
		turnOrderList.append({
			"node": lastCharacterNode,
			"value":  _get_dynamic_speed_value(lastCharacterNode.get_turn_order_value())
		})
		
		turnOrderList.sort_custom(func(a, b): return a.value > b.value)
	elif endlessOrder:
		turnOrderList.append({
			"node": lastCharacterNode,
			"value": lastCharacterNode.get_turn_order_value()
		})

func _set_next_active_character() -> void:
	_remove_active_character()
	
	if turnOrderList.is_empty():
		round_finished.emit()
		_set_turn_order()

	if turnOrderList:
		activeCharacter = turnOrderList[0].node
		activeCharacter.set_active(true)
	
	_send_turn_order_bar()

func _send_turn_order_bar():
	var barTurnOrder: Array[TurnBasedAgent] = []
	
	for character: Dictionary in turnOrderList:
		barTurnOrder.append(character.node)

	turn_order_changed.emit(barTurnOrder)		
	
func _on_turn_done() -> void:
	_send_turn_order_bar()
	_set_next_active_character()
	
func _get_dynamic_speed_value(characterTurnValue: float) -> float:
	var baseSpeed : float = get_tree().get_nodes_in_group("player")[0].get_turn_order_value()
	var speedFactor :float = characterTurnValue * 100.0 / baseSpeed
	var speedValue : float = 1.0 / (speedFactor / 100.0)
	return speedValue

func _add_time_to_turn_order(time) -> void:
	for character: Dictionary in turnOrderList:
		character.value += time
