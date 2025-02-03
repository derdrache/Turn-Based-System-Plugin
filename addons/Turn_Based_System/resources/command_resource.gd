extends Resource
class_name CommandResource

enum Target_Type {ENEMIES, PLAYERS, SELF}
enum Command_Type {DAMAGE, HEAL, SUPPORT}

@export var name : String
@export var manaCost := 0

##Command type is used to determine which group the ability can be targeted at
@export var targetType: Target_Type
@export var commandType: Command_Type

## TargetCount specify how many targets the command should affect [br]
## -1: affect all
@export var targetCount := 1
