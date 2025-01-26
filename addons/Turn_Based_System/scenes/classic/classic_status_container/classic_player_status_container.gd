extends Control

@export_group("Character resource reference")
## variable name in TurnBasedAgent characterResource for name
@export var name_reference := "name"
## variable name in TurnBasedAgent characterResource for current health
@export var health_reference := "currentHealth"
## variable name in TurnBasedAgent characterResource for current mana
@export var mana_reference := "currentMana"
## variable name in TurnBasedAgent characterResource for over drive
@export var over_drive_reference := "overDriveValue"
## variable name in TurnBasedAgent characterResource for max health
@export var max_health_reference := "maxHealth"

@export_group("Customization")
@export var focusStyleBox :StyleBox = preload(
	"res://addons/Turn_Based_System/scenes/classic/classic_status_container/style_box_player_stats_container.tres")
@export var normalStyleBox :StyleBox = StyleBoxEmpty.new()
@export var playerStatsContainer := preload(
	"res://addons/Turn_Based_System/scenes/classic/classic_status_container/player_stats_container.tscn")

@onready var player_container: VBoxContainer = $MarginContainer/PlayerContainer

var currentPlayer: TurnBasedAgent

func _ready() -> void:
	add_to_group("turnBasedStatusContainer")
	
	_set_signals()
	
func _set_signals() -> void:
	var turnBasedController = get_tree().get_first_node_in_group("turnBasedController")
	turnBasedController.new_agent_entered.connect(_on_new_agent)

	for player: TurnBasedAgent in get_tree().get_nodes_in_group("turnBasedPlayer"):
		_on_new_agent(player)

func _on_new_agent(agent: TurnBasedAgent) -> void:
	_refresh()
	
	agent.player_turn_started.connect(_on_player_turn_started.bind(agent))
	agent.targeting_started.connect(_on_targeting_started)
	agent.player_action_started.connect(_on_player_action_started)
	agent.undo_command_selected.connect(_on_undo_command)
	agent.target_changed.connect(_on_target_change)
	
func _refresh():
	_reset_player_container()
	
	_setup_player_stats_container()
	
func _reset_player_container() -> void:
	for node in player_container.get_children():
		node.queue_free()

func _on_player_turn_started(player: TurnBasedAgent) -> void:
	currentPlayer = player
	
	_deactivate_all_player_focus()
	_activate_player(player)

func _deactivate_all_player_focus() -> void:
	for node in player_container.get_children():
		node.deactivate_focus()

func _activate_player(player: TurnBasedAgent = currentPlayer) -> void:
	var index = get_tree().get_nodes_in_group("turnBasedPlayer").find(player)
	player_container.get_children()[index].activate_focus()
	
func _setup_player_stats_container() -> void:
	for player: TurnBasedAgent in get_tree().get_nodes_in_group("turnBasedPlayer"):
		var playerStatsContainer = playerStatsContainer.instantiate()
		
		playerStatsContainer.styleBoxFocus = focusStyleBox
		playerStatsContainer.styleBoxNormal = normalStyleBox
		
		player_container.add_child(playerStatsContainer)
		playerStatsContainer.set_player_stats(player.characterResource)


func _on_targeting_started(targets: Array[TurnBasedAgent], command: Resource) -> void:
	if not command.commandType == command.Command_Type.HEAL: return
	
	for node in player_container.get_children():
		node.set_heal_modus(true)
	
	_on_target_change(targets)
		
func _on_player_action_started(_targets, _command) -> void:
	_deactivate_all_player_focus()

	_deactivate_heal_modus()

func _on_undo_command() -> void:
	_deactivate_all_player_focus()
	_deactivate_heal_modus()
	_activate_player()	

func _deactivate_heal_modus() -> void:
	for node in player_container.get_children():
		node.set_heal_modus(false)

func _on_target_change(targets):
	if not get_tree().get_nodes_in_group("turnBasedPlayer")[0] in targets: return
	
	_deactivate_all_player_focus()
	
	for target in targets:
		var index = get_tree().get_nodes_in_group("turnBasedPlayer").find(target)
		player_container.get_children()[index].activate_focus()
	
func swap_character(oldAgent, newAgent):
	hide()

	var indexOldPlayer = get_tree().get_nodes_in_group("turnBasedPlayer").find(oldAgent)
	get_tree().get_nodes_in_group("turnBasedPlayer")[indexOldPlayer] = newAgent
	
	_reset_player_container()

	_setup_player_stats_container()
	
	await get_tree().create_timer(0.01).timeout
	
	_on_player_turn_started(newAgent)
	
	show()
