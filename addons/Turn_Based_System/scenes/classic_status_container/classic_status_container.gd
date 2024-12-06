extends Control

@export_category("Player Stats Container")
@export var playerStatsContainer := preload("res://addons/Turn_Based_System/scenes/classic_status_container/player_stats_container.tscn")
@export var player_stats_with_focus := preload("res://addons/Turn_Based_System/scenes/classic_status_container/style_box_player_stats_container.tres")
@export var player_stats_without_focus : StyleBox = StyleBoxEmpty.new()

@onready var player_container: VBoxContainer = $MarginContainer/PlayerContainer

var players: Array[TurnBasedAgent] = []

func _ready() -> void:
	_setup()

func _reset():
	for node in player_container.get_children():
		node.queue_free()

func _setup():
	_reset()
	
	_set_players()
	
	_setup_player_stats_container()
	
func _set_players():
	for player: TurnBasedAgent in get_tree().get_nodes_in_group("turnBasedPlayer"):
		players.append(player)
		player.player_turn_started.connect(_on_player_turn_started.bind(player))

func _on_player_turn_started(player: TurnBasedAgent):
	_deactivate_all_player()
	_activate_player(player)

func _deactivate_all_player():
	for node in player_container.get_children():
		node.deactivate()

func _activate_player(player: TurnBasedAgent):
	var index = players.find(player)
	
	player_container.get_children()[index].activate()
	
func _setup_player_stats_container():
	for player: TurnBasedAgent in players:
		var playerStatsContainer = playerStatsContainer.instantiate()
		playerStatsContainer.styleBoxWithFocus = player_stats_with_focus
		playerStatsContainer.styleBoxWithoutFocus = player_stats_without_focus
		playerStatsContainer.character_resource = player.character_resource
		player_container.add_child(playerStatsContainer)
		
