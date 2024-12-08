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
var oldCharacterResource: Resource

func set_character_resource(newCharacterResource):
	character_resource = newCharacterResource

	name_label.text = character_resource[name_resource_reference]
	hp_label_2.text = str(character_resource[current_health_resource_reference])
	mp_label_4.text = str(character_resource[current_mana_resource_reference])
	over_drive_bar.value = character_resource[current_over_drive_resource_reference]

	oldCharacterResource = character_resource.duplicate()
	
func _process(delta: float) -> void:
	if not character_resource: 
		push_error("a turn based agent doesn't have set character resource")
		return
		
	var refreshed = _check_refreshed(character_resource, oldCharacterResource)
	
	if refreshed: 
		_update_stats()
		oldCharacterResource = character_resource.duplicate()

			
func _check_refreshed(newResource: Resource, oldResource):
	var healthChanged = newResource[current_health_resource_reference] != oldResource[current_health_resource_reference]
	var manaChanged = newResource[current_mana_resource_reference] != oldResource[current_mana_resource_reference]
	var overDriveChanged = newResource[current_over_drive_resource_reference] != oldResource[current_over_drive_resource_reference]
	
	if healthChanged or manaChanged or overDriveChanged:
		return true
	
	return false
	
	
func activate():
	_change_style_box(styleBoxWithFocus)
	
func deactivate():
	var styleBox = StyleBoxEmpty.new()
	_change_style_box(styleBoxWithoutFocus)

func _change_style_box(newStyleBox : StyleBox):
	add_theme_stylebox_override("panel", newStyleBox)

func _update_stats():
	_refresh_animation(hp_label_2, character_resource[current_health_resource_reference])
	_refresh_animation(mp_label_4, character_resource[current_mana_resource_reference])
	_refresh_animation(over_drive_bar, character_resource[current_over_drive_resource_reference])

func _refresh_animation(node, newValue: int):
	var tween = get_tree().create_tween()
	
	if node is Label:
		var oldValue = int(node.text)
		tween.tween_method(tween_label.bind(node), oldValue, newValue, 0.3)
	elif node is ProgressBar:
		var oldValue = node.value
		tween.tween_method(tween_progress_bar.bind(node), oldValue, newValue, 0.3)
		
	
func tween_label(value, labelNode):
	labelNode.text = str(value)

func tween_progress_bar(value, progressBarNode):
	progressBarNode.value = value
