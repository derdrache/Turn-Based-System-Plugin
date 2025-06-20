@tool
class_name TurnBasedController extends Node
## This Node controlls the logic for turn based combat
## It has to stay above your TurnOrderBar

## Emit when no enemy or no player left and when all player disabled
signal battle_finished(victory: bool)
## Emit when every character has made his turn [br]
## Doesn't fire if endlessOrder is true
signal round_finished()
## Emit every time when the order has changed
signal turn_order_changed(characterTurnOrder: Array[TurnBasedAgent])

signal active_character_changed(newCharacter)

signal new_agent_entered(agent: TurnBasedAgent)
## Different turn order calculations
@export var turnOrderType : Turn_Order_Type:
	set(value):
		turnOrderType = value
		notify_property_list_changed()
@export var useOwnTargetingSystem := false
@export var manuellStart := false

enum Turn_Order_Type{
	## first the players then the enemies, each character has one turn per round
	CLASSIC, 
	## Value Based: a value determines who is first, each character has one turn per round
	VALUE_BASED, 
	## a value determines who is first, there is nothing like rounds.
	DYNAMIC
	}

var turnOrderList: Array[TimeEntry] = []
var dynamicTurnOrderBaseList: Array[TimeEntry] = []
var activeAgent: TurnBasedAgent

func _ready() -> void:
	add_to_group("turnBasedController")
	
	_set_signals()
	
	if Engine.is_editor_hint(): return
	
	if not manuellStart: _setup()

func _on_new_agent_entered(agent: TurnBasedAgent):
	agent.turn_finished.connect(_on_turn_done)

func _setup():
	await get_tree().process_frame
	
	_set_turn_order()
	
	_set_next_active_character()

	_refresh_turn_order_bar()	

func _set_signals() -> void:
	new_agent_entered.connect(_on_new_agent_entered)
	
	for agent: TurnBasedAgent in get_tree().get_nodes_in_group("turnBasedAgents"):
		agent.turn_finished.connect(_on_turn_done)

func _set_turn_order() -> void:
	turnOrderList = []
	dynamicTurnOrderBaseList = []
	
	var allCharactersList = _get_valid_agents()
	
	for agent: TurnBasedAgent in allCharactersList:
		agent.set_active(false)
	
	match turnOrderType:
		Turn_Order_Type.CLASSIC: _set_classic_turn_order(allCharactersList)
		Turn_Order_Type.VALUE_BASED: _set_value_based_turn_order(allCharactersList)
		Turn_Order_Type.DYNAMIC: _set_dynamic_turn_order(allCharactersList)
	
func _set_classic_turn_order(characterList: Array) -> void:
		for agent: TurnBasedAgent in characterList:
			var timeEntry := TimeEntry.new()
			timeEntry.agent = agent
			
			turnOrderList.append(timeEntry)
		
func _set_value_based_turn_order(characterList: Array) -> void:
	for agent: TurnBasedAgent in characterList:
		var timeEntry := TimeEntry.new()
		timeEntry.agent = agent
		timeEntry.currentTime = agent.get_turn_order_value()
		
		turnOrderList.append(timeEntry)

	_sort_turn_order_list_by_time()

func _set_dynamic_turn_order(characterList) -> void:
	for agent: TurnBasedAgent in characterList:
		const TIME_ANKER = 10.0
		var speedValue : float = _get_dynamic_speed_value(agent.get_turn_order_value())
		
		var timeEntry := TimeEntry.new()
		timeEntry.agent = agent
		timeEntry.currentTime = TIME_ANKER - speedValue
	
		dynamicTurnOrderBaseList.append(timeEntry)
	
	_refresh_dynamic_turn_order_list()

func _set_next_active_character() -> void:	
	activeAgent = turnOrderList[0].agent
	activeAgent.set_active(true)
	
	if turnOrderType == Turn_Order_Type.DYNAMIC: 
		_reduce_time_on_same_as_active()

	active_character_changed.emit(activeAgent.get_parent())

func _reduce_time_on_same_as_active():
		for entry in dynamicTurnOrderBaseList:
			if entry.agent != activeAgent and entry.currentTime == turnOrderList[0].currentTime:
				entry.currentTime -= 0.01


func _refresh_turn_order():
	if turnOrderType == Turn_Order_Type.DYNAMIC: 
		_add_time_to_turn_order()
		_reduce_time_on_active_char()
		_refresh_dynamic_turn_order_list()
		
		while turnOrderList[0].agent.isDisabled:
			_add_time_to_turn_order()
			_reduce_time_on_active_char()
			_refresh_dynamic_turn_order_list()
	else: 
		_remove_active_character()
	
		if turnOrderList.is_empty():
			round_finished.emit()
			_set_turn_order()
		
		if turnOrderList[0].agent.isDisabled:
			turnOrderList.pop_front()
			_refresh_turn_order()

func _refresh_dynamic_turn_order_list() -> void:
	var agentList = _get_valid_agents()
	turnOrderList = []
	
	for agent in agentList:
		var found = false
		
		for entry in dynamicTurnOrderBaseList:
			if entry.agent == agent: found = true
			
		if not found: 
			_add_dynamic_agent(agent)
	
	for entry in dynamicTurnOrderBaseList:
		if entry.agent == null: continue
		
		var speedValue : float = _get_dynamic_speed_value(entry.agent.get_turn_order_value())
		var currentTime : float = entry.currentTime
		
		while currentTime > 0:
			var timeEntry := TimeEntry.new()
			timeEntry.agent = entry.agent
			timeEntry.currentTime = currentTime
			
			turnOrderList.append(timeEntry)
			
			currentTime -= speedValue
	
	_sort_turn_order_list_by_time()

func _get_valid_agents():
	var players = get_tree().get_nodes_in_group("turnBasedPlayer")
	var enemies = get_tree().get_nodes_in_group("turnBasedEnemy")
	var validAgents = players + enemies

	for agent:TurnBasedAgent in validAgents:
		
		if agent.isDisabled or agent.character_type == TurnBasedAgent.Character_Type.PASSIV_PLAYER:
			validAgents.erase(agent)
	
	return validAgents

func _remove_active_character() -> void:
	if not activeAgent: return
	
	turnOrderList.pop_front()		

func _refresh_turn_order_bar():
	var barTurnOrder: Array[TurnBasedAgent] = []
	
	for entry: TimeEntry in turnOrderList:
		if entry.agent.isDisabled: continue
		barTurnOrder.append(entry.agent)

	turn_order_changed.emit(barTurnOrder)		
	
func _on_turn_done() -> void:
	var battleDone = _check_battle_done()
	
	if battleDone: return
	
	activeAgent.set_active(false)
	
	_refresh_turn_order()
	
	_set_next_active_character()
	
	_refresh_turn_order_bar()
	
func _check_battle_done():
	var allEnemies = get_tree().get_nodes_in_group("turnBasedEnemy").filter(func(character): return not character.isDisabled)
	var allPlayer = get_tree().get_nodes_in_group("turnBasedPlayer")

	var noEnemies = allEnemies.size() == 0
	var noPlayers = allPlayer.size() == 0
	var allPlayerDisabled = allPlayer.filter(
		func(player: TurnBasedAgent): return not player.isDisabled).size() == 0
	
	if noEnemies or allPlayerDisabled or noPlayers:
		_battle_done()
		return true
		
	return false
		

func _battle_done():
	get_tree().get_first_node_in_group("turnBasedCommandMenu").hide()
	get_tree().get_first_node_in_group("turnBasedStatusContainer").hide()
	get_tree().get_first_node_in_group("turnBasedTurnOrderBar").hide()

	var activeEnemies = get_tree().get_nodes_in_group("turnBasedEnemy").filter(func(character): return not character.isDisabled)
	var victory = activeEnemies.is_empty()

	battle_finished.emit(victory)

func _get_dynamic_speed_value(characterTurnValue: float) -> float:
	var baseSpeed : float = get_tree().get_nodes_in_group("turnBasedPlayer")[0].get_turn_order_value()
	var speedFactor :float = characterTurnValue * 100.0 / baseSpeed
	var speedValue : float = 1.0 / (speedFactor / 100.0)
	
	return snapped(speedValue, 0.01)

func get_command_speed_cost():
	var activeCharCommand = turnOrderList[0].agent.currentCommand
	
	if not activeCharCommand:
		return 1
		
	var commandSpeedCost = activeCharCommand.turnOrderCost
	
	return 1 + commandSpeedCost

func _reduce_time_on_active_char():
	var activeChar = turnOrderList[0].agent
	var speedValue : float = _get_dynamic_speed_value(activeChar.get_turn_order_value()) 

	for entry in dynamicTurnOrderBaseList:
		if entry.agent == activeChar:
			entry.currentTime -= speedValue * get_command_speed_cost()

func _add_time_to_turn_order() -> void:
	var firstCharacterTime = turnOrderList[0].currentTime
	var secondsCharacterTime = turnOrderList[1].currentTime
	var timeChange = firstCharacterTime - secondsCharacterTime
	
	for entry: TimeEntry in dynamicTurnOrderBaseList:
		entry.currentTime += timeChange

func _sort_turn_order_list_by_time():
	turnOrderList.sort_custom(func(a, b): return a.currentTime > b.currentTime)	

func _swap_agents_classic_mode(oldAgent: TurnBasedAgent, newAgent: TurnBasedAgent, turnOrderTakeOver):
	if turnOrderTakeOver:
		oldAgent.set_active(false)
		
		for i in turnOrderList.size():
			if turnOrderList[i].agent == oldAgent:
				turnOrderList[i].agent = newAgent
				
		activeAgent = newAgent
		activeAgent.set_active(true)
		
		_refresh_turn_order_bar()
	else:
		_on_turn_done()

func _swap_agents_dynamic_mode(oldAgent: TurnBasedAgent, newAgent: TurnBasedAgent, turnOrderTakeOver):
	if turnOrderTakeOver:
		oldAgent.set_active(false)
		
		for i in dynamicTurnOrderBaseList.size():
			if dynamicTurnOrderBaseList[i].agent == oldAgent:
				dynamicTurnOrderBaseList[i].agent = newAgent
		activeAgent = newAgent
		activeAgent.set_active(true)
		
		_refresh_dynamic_turn_order_list()
		_refresh_turn_order_bar()
	else:
		_remove_dynamic_agent(oldAgent)
		_add_dynamic_agent(newAgent)
		_refresh_dynamic_turn_order_list()
		
		_on_turn_done()

func _add_dynamic_agent(agent:TurnBasedAgent) -> void:
	var speedValue : float = _get_dynamic_speed_value(agent.get_turn_order_value())
	var timeEntry := TimeEntry.new()
	
	timeEntry.agent = agent
	timeEntry.currentTime = 10 - 2 * speedValue
	dynamicTurnOrderBaseList.append(timeEntry)

func _remove_dynamic_agent(agent: TurnBasedAgent) -> void:
	var removeIndex = -1
	
	for i in dynamicTurnOrderBaseList.size():
		if dynamicTurnOrderBaseList[i].agent == agent: 
			removeIndex = 1
			break
	
	if removeIndex >= 0:
		dynamicTurnOrderBaseList.remove_at(removeIndex)


func swap_agents(oldAgent: TurnBasedAgent, newAgent: TurnBasedAgent, turnOrderTakeOver = true):
	oldAgent.isDisabled = true
	newAgent.isDisabled = false
	
	var statusContainer = get_tree().get_first_node_in_group("turnBasedStatusContainer")
	if statusContainer: statusContainer.swap_character(oldAgent, newAgent)
	
	match turnOrderType:
		Turn_Order_Type.CLASSIC: _swap_agents_classic_mode(oldAgent, newAgent, turnOrderTakeOver)
		Turn_Order_Type.VALUE_BASED: _swap_agents_classic_mode(oldAgent, newAgent, turnOrderTakeOver)
		Turn_Order_Type.DYNAMIC: _swap_agents_dynamic_mode(oldAgent, newAgent, turnOrderTakeOver)

func add_agent(agent:TurnBasedAgent) -> void:
	turnOrderList.append(agent)
	
	_refresh_turn_order_bar()

func remove_agent(agent: TurnBasedAgent) -> void:
	for entry: TimeEntry in turnOrderList:
		if entry.agent == agent: 
			turnOrderList.erase(entry)
	
	for entry in dynamicTurnOrderBaseList:
		if entry.agent == agent: 
			dynamicTurnOrderBaseList.erase(entry)
	
	_refresh_turn_order_bar()

func get_active_character():
	return activeAgent.get_parent()

func start():
	turnOrderList = []
	dynamicTurnOrderBaseList = []
	
	_setup()

## dynamic inspector
func _validate_property(property: Dictionary):
	var hideList = []
	
	if property.name in hideList: 
		property.usage = PROPERTY_USAGE_NO_EDITOR 
