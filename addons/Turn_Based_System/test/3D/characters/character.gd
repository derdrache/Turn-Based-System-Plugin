extends StaticBody3D

@export var characterResource: Resource

@onready var turn_based_agent: TurnBasedAgent = $TurnBasedAgent

func _ready() -> void:
	if turn_based_agent: 
		turn_based_agent.target_selected.connect(_on_character_action)
		turn_based_agent.character_resource = characterResource
		turn_based_agent.turnOrderValueName = "speed"
	
func _on_character_action(targets,command):
	# here you put every interaction between the character and his targets
	# like:
	# animation
	# damage/heal/buffs
	# interaction with Hp Bars
	# and more

	if command.name == "Haste":
		for target in targets:
			target.character_resource.speed *=2

	await _animation_example(targets)
	
	turn_based_agent.command_done()

func _animation_example(targets):
	var startPosition = global_position
	var targetPosition
	
	if turn_based_agent.get_targets():
		targetPosition = turn_based_agent.get_targets().get_global_position()
	else: 
		var randomTarget = get_tree().get_nodes_in_group("turnBasedPlayer").pick_random()
		targetPosition = randomTarget.get_global_position()
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", targetPosition, 0.5)
	tween.tween_property(self, "global_position", startPosition, 0.5)
	
	await tween.finished
	
	
