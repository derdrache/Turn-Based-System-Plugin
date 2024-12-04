extends Resource
class_name CommandResource

enum Target_Type {ENEMIES, PLAYERS, SELF}

@export var name : String

##Command type is used to determine which group the ability can be targeted at
@export var targetType: Target_Type

## TargetCount specify how many targets the command should affect [br]
## -1: affect all
@export var targetCount := 1
