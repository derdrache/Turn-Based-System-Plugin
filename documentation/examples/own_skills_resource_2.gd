extends Resource

enum Target_Type {ENEMIES, PLAYERS}

@export var name : String
@export var targetType: Target_Type
@export var targetCount := 1
