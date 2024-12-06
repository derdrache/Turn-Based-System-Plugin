extends PanelContainer

## variable name in character_resource for name
@export var name_resource_reference := "name"
## variable name in character_resource for current health
@export var current_health_resource_reference := "currentHealth"
## variable name in character_resource for current mana
@export var current_mana_resource_reference := "currentMana"

@onready var name_label: Label = %NameLabel
@onready var hp_label_2: Label = %HPLabel2
@onready var mp_label_4: Label = %MPLabel4

var character_resource: Resource

const STYLE_BOX_PLAYER_STATS_CONTAINER = preload("res://addons/Turn_Based_System/scenes/classic_status_container/style_box_player_stats_container.tres")

func _ready() -> void:
	var styleBox = StyleBoxEmpty.new()
	_change_style_box(styleBox)	

func _process(delta: float) -> void:
	if not character_resource: 
		push_error("a turn based agent doesn't have set character resource")
		return

	name_label.text = str(character_resource[name_resource_reference])
	hp_label_2.text = str(character_resource[current_health_resource_reference])
	mp_label_4.text = str(character_resource[current_mana_resource_reference])

func activate():
	_change_style_box(STYLE_BOX_PLAYER_STATS_CONTAINER)
	
func deactivate():
	var styleBox = StyleBoxEmpty.new()
	_change_style_box(styleBox)

func _change_style_box(newStyleBox : StyleBox):
	add_theme_stylebox_override("panel", newStyleBox)
