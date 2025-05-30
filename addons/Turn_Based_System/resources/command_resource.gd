extends Resource
class_name CommandResource

## None: after command selection, you have to use "manual_target_selection" from the turn based agent to continue the battle
enum Target_Type {ENEMIES, PLAYERS, SELF, PLAYERS_NOT_SELF, PLAYERS_WITH_DISABLED, OWN_MINIONS, NONE}
enum Command_Type {DAMAGE, HEAL, SUPPORT}

@export var name : String
@export var manaCost := 0
## turnOrderCost influences the turnorder. 
## Only has an effect if “turnOrderType” == ‘dynamic’ on "turnBasedController"
## if -0.1 => command cost 10% less turnOrderValue
## if +0.2 => command costs 20% more turnOrderValue
@export_range(-1.0, 1.0, 0.01) var turnOrderCost := 0.0
@export var isAllowed = true

##Command type is used to determine which group the ability can be targeted at
@export var targetType: Target_Type
@export var commandType: Command_Type

## TargetCount specify how many targets the command should affect [br]
## -1: affect all
@export var targetCount := 1
