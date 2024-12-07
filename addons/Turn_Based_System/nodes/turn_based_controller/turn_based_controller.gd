@tool
class_name TurnBasedController extends Node
## This Node controlls the logic for turn based combat
## It has to stay above your TurnOrderBar

## Emit when every character has made his turn [br]
## Doesn't fire if endlessOrder is true
signal round_finished()
## Emit every time when the order has changed
signal turn_order_changed(characterTurnOrder: Array[TurnBasedAgent])

## Different turn order calculations
@export var turnOrderType : Turn_Order_Type:
	set(value):
		turnOrderType = value
		notify_property_list_changed()

@export_category("targeting system")
@export var useOwnTargetingSystem := false

enum Turn_Order_Type{
	## first the players then the enemies, each character has one turn per round
	CLASSIC, 
	## Value Based: a value determines who is first, each character has one turn per round
	VALUE_BASED, 
	## a value determines who is first, there is nothing like rounds.
	DYNAMIC
	}

var turnOrderList: Array[TimeEntry] = []
var dynamicTimeOrderList: Array[TimeEntry] = []
var activeCharacter: TurnBasedAgent

func _ready() -> void:
	add_to_group("turnBasedController")
	
	await get_tree().create_timer(0.1).timeout
	
	_set_signals()

	_set_turn_order()
	
	_set_next_active_character()

	_refresh_turn_order_bar()

func _set_signals() -> void:
	for agent: TurnBasedAgent in get_tree().get_nodes_in_group("turnBasedAgents"):
		agent.turn_finished.connect(_on_turn_done)

func _set_turn_order() -> void:
	var players = get_tree().get_nodes_in_group("turnBasedPlayer")
	var enemies = get_tree().get_nodes_in_group("turnBasedEnemy")
	
	match turnOrderType:
		Turn_Order_Type.CLASSIC: _set_classic_turn_order(players + enemies)
		Turn_Order_Type.VALUE_BASED: _set_value_based_turn_order(players + enemies)
		Turn_Order_Type.DYNAMIC: _set_dynamic_turn_order(players + enemies)
	
func _set_classic_turn_order(characterList) -> void:
		for agent: TurnBasedAgent in characterList:
			turnOrderList.append({
				"agent": agent
			})
		
func _set_value_based_turn_order(characterList) -> void:
	for agent: TurnBasedAgent in characterList:
		turnOrderList.append({
			"agent": agent,
			"value": agent.get_turn_order_value()
		})
	
	_sort_turn_order_list_by_time()

func _set_dynamic_turn_order(characterList) -> void:
	for agent: TurnBasedAgent in characterList:
		var speedValue : float = _get_dynamic_speed_value(agent.get_turn_order_value())
		var timeEntry := TimeEntry.new()
		timeEntry.agent = agent
		timeEntry.currentTime = 10 - speedValue
	
		dynamicTimeOrderList.append(timeEntry)
	
	_refresh_dynamic_turn_order()

func _refresh_turn_order():
	if turnOrderType == Turn_Order_Type.DYNAMIC: 
		_refresh_dynamic_turn_order()
	else: 
		_remove_active_character()
	
	if turnOrderList.is_empty():
		round_finished.emit()
		_set_turn_order()

func _refresh_dynamic_turn_order() -> void:
	var players = get_tree().get_nodes_in_group("turnBasedPlayer")
	var enemies = get_tree().get_nodes_in_group("turnBasedEnemy")
	var agentList = players + enemies
	turnOrderList = []

	for agent in agentList:
		var found = false
		
		for entry in dynamicTimeOrderList:
			if entry.agent == agent: found = true
			
		if not found: 
			var speedValue : float = _get_dynamic_speed_value(agent.get_turn_order_value())
			var timeEntry := TimeEntry.new()
			
			timeEntry.agent = agent
			timeEntry.currentTime = 10 - 2 * speedValue
			
			dynamicTimeOrderList.append(timeEntry)
	
	for entry in dynamicTimeOrderList:
		var speedValue : float = _get_dynamic_speed_value(entry.agent.get_turn_order_value())
		var currentTime : float = entry.currentTime
		
		while currentTime > 0:
			var timeEntry := TimeEntry.new()
			timeEntry.agent = entry.agent
			timeEntry.currentTime = currentTime
			
			turnOrderList.append(timeEntry)
			
			currentTime -= speedValue
	
	_sort_turn_order_list_by_time()
	
func _remove_active_character() -> void:
	if not activeCharacter: return
	
	var lastCharacter := turnOrderList.pop_front()
	var lastCharacterNode : TurnBasedAgent = lastCharacter.agent

func _set_next_active_character() -> void:		
	activeCharacter = turnOrderList[0].agent
	activeCharacter.set_active(true)

func _refresh_turn_order_bar():
	var barTurnOrder: Array[TurnBasedAgent] = []
	
	for entry: TimeEntry in turnOrderList:
		barTurnOrder.append(entry.agent)

	turn_order_changed.emit(barTurnOrder)		
	
func _on_turn_done() -> void:
	_add_time_to_turn_order()
	
	_reduce_dynamic_time(turnOrderList[0].agent)
	
	_refresh_turn_order()
	
	_set_next_active_character()
	
	_refresh_turn_order_bar()
	
func _get_dynamic_speed_value(characterTurnValue: float) -> float:
	var baseSpeed : float = get_tree().get_nodes_in_group("turnBasedPlayer")[0].get_turn_order_value()
	var speedFactor :float = characterTurnValue * 100.0 / baseSpeed
	var speedValue : float = 1.0 / (speedFactor / 100.0)
	
	return snapped(speedValue, 0.01)

func _reduce_dynamic_time(agent: TurnBasedAgent):
	var speedValue : float = _get_dynamic_speed_value(agent.get_turn_order_value())
	
	for entry in dynamicTimeOrderList:
		if entry.agent == agent:
			entry.currentTime -= speedValue

func _add_time_to_turn_order() -> void:
	var firstCharacterTime = turnOrderList[0].currentTime
	var secondsCharacterTime = turnOrderList[1].currentTime
	var timeChange = firstCharacterTime - secondsCharacterTime
	
	for entry: TimeEntry in dynamicTimeOrderList:
		entry.currentTime += timeChange

func _sort_turn_order_list_by_time():
	turnOrderList.sort_custom(func(a, b): return a.currentTime > b.currentTime)	

## returns the parent of the TurnBasedAgent
func get_active_character():
	return activeCharacter.get_parent()

## dynamic inspector
func _validate_property(property: Dictionary):
	var hideList = []
	
	if property.name in hideList: 
		property.usage = PROPERTY_USAGE_NO_EDITOR 
