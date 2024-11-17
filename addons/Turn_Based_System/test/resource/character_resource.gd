extends Resource
class_name CharacterResource

## Here you setup your stats, skills, items and what you want
@export var health := 100
@export var speed := 50

@export var basicAttack: Resource
@export var skills: Array[Resource]
@export var items: Array[Resource]
