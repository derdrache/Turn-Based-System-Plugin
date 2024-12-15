extends PanelContainer

@onready var name_label: Label = %NameLabel
@onready var hp_label_2: Label = %HPLabel2
@onready var mp_label_4: Label = %MPLabel4
@onready var over_drive_bar: ProgressBar = $MarginContainer/VBoxContainer/overDriveBar

var characterResource: Resource
var statsReference: Dictionary = {}
var styleBoxNormal: StyleBox
var styleBoxFocus: StyleBox 
var oldCharacterResource: Resource

func set_player_stats(newCharacterResource: Resource) -> void:
	characterResource = newCharacterResource
	
	var statusContainer = get_tree().get_first_node_in_group("turnBasedStatusContainer")
	statsReference = {
		"health": statusContainer.health_reference,
		"mana": statusContainer.mana_reference,
		"overDrive": statusContainer.over_drive_reference
	}

	name_label.text = characterResource[statusContainer.name_reference]
	hp_label_2.text = str(characterResource[statsReference["health"]])
	mp_label_4.text = str(characterResource[statsReference["mana"]])
	over_drive_bar.value = characterResource[statsReference["overDrive"]]

	oldCharacterResource = characterResource.duplicate()
	
func _process(delta: float) -> void:
	if not characterResource: 
		push_error("a turn based agent doesn't have set character resource")
		return
		
	var refreshed = _check_refreshed(characterResource, oldCharacterResource)
	
	if refreshed: 
		_update_stats()
		oldCharacterResource = characterResource.duplicate()

func _check_refreshed(newResource: Resource, oldResource) -> bool:
	var healthChanged = newResource[statsReference["health"]] != oldResource[statsReference["health"]]
	var manaChanged = newResource[statsReference["mana"]] != oldResource[statsReference["mana"]]
	var overDriveChanged = newResource[statsReference["overDrive"]] != oldResource[statsReference["overDrive"]]
	
	if healthChanged or manaChanged or overDriveChanged:
		return true
	
	return false
	
func activate_focus() -> void:
	add_theme_stylebox_override("panel", styleBoxFocus)
	
func deactivate_focus() -> void:
	add_theme_stylebox_override("panel", styleBoxNormal)

func _update_stats() -> void:
	_refresh_animation(hp_label_2, characterResource[statsReference["health"]])
	_refresh_animation(mp_label_4, characterResource[statsReference["mana"]])
	_refresh_animation(over_drive_bar, characterResource[statsReference["overDrive"]])

func _refresh_animation(node: Control, newValue: int) -> void:
	var tween = get_tree().create_tween()
	
	if node is Label:
		var oldValue = int(node.text)
		tween.tween_method(tween_label.bind(node), oldValue, newValue, 0.3)
	elif node is ProgressBar:
		var oldValue = node.value
		tween.tween_method(tween_progress_bar.bind(node), oldValue, newValue, 0.3)
		
func tween_label(value: int, labelNode: Label):
	labelNode.text = str(value)

func tween_progress_bar(value: int, progressBarNode: ProgressBar):
	progressBarNode.value = value
