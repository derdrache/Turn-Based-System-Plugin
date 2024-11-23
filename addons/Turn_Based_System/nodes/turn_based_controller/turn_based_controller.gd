@tool
class_name TurnBasedController extends Node
## This Node controlls the logic for turn based combat
## It has to stay above your TurnOrderBar

## Emit when every character has made his turn [br]
## Doesn't fire if endlessOrder is true
signal round_finished()
## Emit every time when the order has changed
signal turn_order_changed(characterTurnOrder)

## Different turn order calculations
@export var turnOrderType : Turn_Order_Type:
	set(value):
		turnOrderType = value
		notify_property_list_changed()

@export_category("Endless Turn Modus")
## if true, turnOrderList saved more then one round on character turns
@export var endlessOrder := false:
	set(value):
		endlessOrder = value
		notify_property_list_changed()
## Number of turns that calculate in turnOrderList
@export var endlessTurnDisplay := 15

@export_category("targeting system")
@export var useOwnTargetingSystem := false

func _validate_property(property: Dictionary):
	var hideList = []
	
	if turnOrderType == Turn_Order_Type.CLASSIC:
		hideList.append("endlessTurnDisplay")
	if not endlessOrder: 
		hideList.append("endlessTurnDisplay")
	
	if property.name in hideList: 
		property.usage = PROPERTY_USAGE_NO_EDITOR 

enum Turn_Order_Type{
	## first the players then the enemies, each character has one turn per round
	CLASSIC, 
	## Value Based: a value determines who is first, each character has one turn per round
	VALUE_BASED, 
	## a value determines who is first, there is nothing like rounds.
	DYNAMIC
	}


var turnOrderList: Array[Dictionary] = []
var activeCharacter: TurnBasedAgent

func _ready() -> void:
	add_to_group("turnBasedController")
	
	await get_tree().create_timer(0.1).timeout
	
	_set_signals()

	_set_turn_order()
	
	_set_next_active_character()

func _set_signals() -> void:
	for player: TurnBasedAgent in get_tree().get_nodes_in_group("turnBasedAgents"):
		player.turn_finished.connect(_on_turn_done)

func _set_turn_order() -> void:
	var players = get_tree().get_nodes_in_group("turnBasedPlayer")
	var enemies = get_tree().get_nodes_in_group("turnBasedEnemy")
	
	match turnOrderType:
		Turn_Order_Type.CLASSIC: _set_classic_turn_order(players + enemies)
		Turn_Order_Type.VALUE_BASED: _set_value_based_turn_order(players + enemies)
		Turn_Order_Type.DYNAMIC: _set_dynamic_turn_order(players + enemies)
	
func _set_classic_turn_order(characterList) -> void:
		var rounds := 1
		if endlessOrder: rounds = round(endlessTurnDisplay / (characterList).size())
		
		for i in rounds:
			for character: TurnBasedAgent in characterList:
				turnOrderList.append({
					"node": character
				})
		
func _set_value_based_turn_order(characterList) -> void:
	var rounds := 1
	if endlessOrder: rounds = round(endlessTurnDisplay / (characterList).size())
	
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
	var baseSpeed : float = get_tree().get_nodes_in_group("turnBasedPlayer")[0].get_turn_order_value()
	var speedFactor :float = characterTurnValue * 100.0 / baseSpeed
	var speedValue : float = 1.0 / (speedFactor / 100.0)
	return speedValue

func _add_time_to_turn_order(time) -> void:
	for character: Dictionary in turnOrderList:
		character.value += time

## returns the parent of the TurnBasedAgent
func get_active_character():
	return activeCharacter.get_parent()
