extends Control

@export_group("Character resource reference")
## variable name in TurnBasedAgent character_resource for name
@export var name_reference := "name"
## variable name in TurnBasedAgent character_resource for current health
@export var health_reference := "currentHealth"
## variable name in TurnBasedAgent character_resource for current mana
@export var mana_reference := "currentMana"
## variable name in TurnBasedAgent character_resource for over drive
@export var over_drive_reference := "overDriveValue"

@export_group("Player Stats Container")
@export var focusStyleBox :StyleBox = preload("res://addons/Turn_Based_System/scenes/classic_status_container/style_box_player_stats_container.tres")
@export var normalStyleBox :StyleBox = StyleBoxEmpty.new()
@export var playerStatsContainer := preload("res://addons/Turn_Based_System/scenes/classic_status_container/player_stats_container.tscn")

@onready var player_container: VBoxContainer = $MarginContainer/PlayerContainer

var players: Array[TurnBasedAgent] = []

func _ready() -> void:
	add_to_group("turnBasedStatusContainer")
	
	_setup()
	
func _setup() -> void:
	_reset_player_container()
	
	_set_player_agents()
	
	_setup_player_stats_container()
	
func _reset_player_container() -> void:
	for node in player_container.get_children():
		node.queue_free()

func _set_player_agents() -> void:
	for player: TurnBasedAgent in get_tree().get_nodes_in_group("turnBasedPlayer"):
		players.append(player)
		player.player_turn_started.connect(_on_player_turn_started.bind(player))

func _on_player_turn_started(player: TurnBasedAgent) -> void:
	_deactivate_all_player_focus()
	_activate_player(player)

func _deactivate_all_player_focus() -> void:
	for node in player_container.get_children():
		node.deactivate_focus()

func _activate_player(player: TurnBasedAgent) -> void:
	var index = players.find(player)
	
	player_container.get_children()[index].activate_focus()
	
func _setup_player_stats_container() -> void:
	for player: TurnBasedAgent in players:
		var playerStatsContainer = playerStatsContainer.instantiate()
		
		playerStatsContainer.styleBoxFocus = focusStyleBox
		playerStatsContainer.styleBoxNormal = normalStyleBox
		player_container.add_child(playerStatsContainer)
		
		playerStatsContainer.set_player_stats(player.character_resource)
