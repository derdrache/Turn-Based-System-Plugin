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

var playerList: Array
var currentPlayer: TurnBasedAgent

func _ready() -> void:
	add_to_group("turnBasedStatusContainer")
	
	playerList = get_tree().get_nodes_in_group("turnBasedPlayer")
	
	_setup()
	
func _setup() -> void:
	_reset_player_container()
	
	_setup_normal_player_stats_container()
	
	_set_signals()
	
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
	var index = playerList.find(player)
	
	player_container.get_children()[index].activate_focus()
	
func _setup_normal_player_stats_container() -> void:
	for player: TurnBasedAgent in playerList:
		var playerStatsContainer = playerStatsContainer.instantiate()
		
		playerStatsContainer.styleBoxFocus = focusStyleBox
		playerStatsContainer.styleBoxNormal = normalStyleBox
		player_container.add_child(playerStatsContainer)
		
		playerStatsContainer.set_player_stats(player.characterResource)

func _set_signals() -> void:
	for player: TurnBasedAgent in playerList:
		player.player_turn_started.connect(_on_player_turn_started.bind(player))
		player.targeting_started.connect(_on_targeting_started)
		player.player_action_started.connect(_on_player_action_started)
		player.undo_command_selected.connect(_on_undo_command)
		player.target_changed.connect(_on_target_change)


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
	_deactivate_all_player_focus()
	
	for target in targets:
		var index = playerList.find(target)
		player_container.get_children()[index].activate_focus()
	
