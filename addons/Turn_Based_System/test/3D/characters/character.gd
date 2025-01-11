extends StaticBody3D

@export var characterResource: Resource

@onready var turn_based_agent: TurnBasedAgent = $TurnBasedAgent

const KNIGHT = preload("res://addons/Turn_Based_System/test/3D/characters/knight.tscn")
const AGENT = preload("res://addons/Turn_Based_System/assets/icons/agent.png")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_swap_character()

func _swap_character():	
	if not turn_based_agent.isActive: return
	
	var startPosition = Vector3(0,0,0)
	var target_position = global_position

	var knightNode = load("res://addons/Turn_Based_System/test/3D/characters/testChar.tscn").instantiate()

	get_tree().current_scene.add_child(knightNode)
	knightNode.global_position = startPosition
	
	turn_based_agent.swap_agent(knightNode.turn_based_agent , true)
	
	queue_free()

func _ready() -> void:
	if turn_based_agent: 
		turn_based_agent.player_action_started.connect(_on_character_action)
		turn_based_agent.enemy_turn_started.connect(_on_enemy_turn_started)
		turn_based_agent.characterResource = characterResource
		turn_based_agent.turnOrderValueName = "speed"

func _on_character_action(targets ,command):
	# here you put every interaction between the character and his targets
	# like:
	# animation
	# damage/heal/buffs
	# interaction with Hp Bars
	# and more
	await _animation_example(targets[0])
	
	if command.name == "Haste":
		for target in targets:
			target.character_resource.speed *=2
	elif command.name == "Summon":
		var knightNode = KNIGHT.instantiate()
		knightNode.characterResource = characterResource.duplicate()
		get_tree().current_scene.add_child(knightNode)
		knightNode.global_position = global_position + Vector3(-5,0,0)
		knightNode.turn_based_agent.turnOrderBarIconTexture = AGENT
	else:
		for target: TurnBasedAgent in targets:
			target.get_parent().take_damage(50)
	
	characterResource.overDriveValue += 5
	
	turn_based_agent.command_done()

func _on_enemy_turn_started():
	var allPlayer = get_tree().get_nodes_in_group("turnBasedPlayer")
	allPlayer.filter(func(player: TurnBasedAgent): return player.isDisabled)
	var target = allPlayer.pick_random()
	
	await _animation_example(target)
	
	target.characterResource.take_damage(10)
	
	turn_based_agent.command_done()

func _animation_example(target):
	var startPosition = global_position
	var targetPosition
	
	if target:
		targetPosition = target.get_global_position()
	else: 
		var randomTarget = get_tree().get_nodes_in_group("turnBasedPlayer").pick_random()
		targetPosition = randomTarget.get_global_position()
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", targetPosition, 0.5)
	tween.tween_property(self, "global_position", startPosition, 0.5)
	
	await tween.finished

func take_damage(damage):
	characterResource.currentHealth -= damage
	
	if characterResource.currentHealth <= 0:
		queue_free()
