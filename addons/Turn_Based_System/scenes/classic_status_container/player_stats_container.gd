extends PanelContainer

## variable name in character_resource for name
@export var name_resource_reference := "name"
## variable name in character_resource for current health
@export var current_health_resource_reference := "currentHealth"
## variable name in character_resource for current mana
@export var current_mana_resource_reference := "currentMana"
## variable name in character_resource for over drive
@export var current_over_drive_resource_reference := "overDriveValue"

@onready var name_label: Label = %NameLabel
@onready var hp_label_2: Label = %HPLabel2
@onready var mp_label_4: Label = %MPLabel4
@onready var over_drive_bar: ProgressBar = $MarginContainer/VBoxContainer/overDriveBar

var character_resource: Resource
var styleBoxWithFocus: StyleBox
var styleBoxWithoutFocus: StyleBox 

func _ready() -> void:
	_change_style_box(styleBoxWithoutFocus)	

func _process(delta: float) -> void:
	if not character_resource: 
		push_error("a turn based agent doesn't have set character resource")
		return

	name_label.text = str(character_resource[name_resource_reference])
	hp_label_2.text = str(character_resource[current_health_resource_reference])
	mp_label_4.text = str(character_resource[current_mana_resource_reference])
	over_drive_bar.value = character_resource[current_over_drive_resource_reference]

func activate():
	_change_style_box(styleBoxWithFocus)
	
func deactivate():
	var styleBox = StyleBoxEmpty.new()
	_change_style_box(styleBoxWithoutFocus)

func _change_style_box(newStyleBox : StyleBox):
	add_theme_stylebox_override("panel", newStyleBox)
