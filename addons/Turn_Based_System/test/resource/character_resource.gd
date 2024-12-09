extends Resource
class_name TestCharacterResource

@export var name := "Name"

## Here you setup your stats, skills, items and what you want
@export var maxHealth := 100
@export var currentHealth := 100
@export var maxMana := 50
@export var currentMana := 50
@export var speed := 50
@export var overDriveValue := 0

@export var basicAttack: Resource
@export var skills: Array[Resource]
@export var items: Array[Resource]

func take_damage(damage):
	currentHealth -= damage

	if currentHealth < 0: currentHealth = 0
