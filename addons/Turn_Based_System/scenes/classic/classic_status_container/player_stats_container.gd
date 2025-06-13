extends PanelContainer

@onready var name_label: Label = %NameLabel
@onready var hp_label_2: Label = %HPLabel2
@onready var mp_label_4: Label = %MPLabel4
@onready var over_drive_bar: ProgressBar = $MarginContainer/VBoxContainer/overDriveBar
@onready var mp_box: HBoxContainer = %MPBox
@onready var hp_max_box: HBoxContainer = %HPMaxBox
@onready var max_hp_2: Label = %maxHP2

var characterResource: Resource
var statsReference: Dictionary = {}
var styleBoxNormal: StyleBox = StyleBoxEmpty.new()
var styleBoxFocus: StyleBox = StyleBoxEmpty.new()
var oldCharacterResource: Resource
var styleBoxHealFocus := preload(
	"res://addons/Turn_Based_System/scenes/classic/classic_status_container/style_box_player_stats_container_heal.tres"
	)
var healMode := false

var health := 0
var mana := 0
var overDrive := 0

func set_player_stats(newCharacterResource: Resource) -> void:
	characterResource = newCharacterResource

	var statusContainer = get_tree().get_first_node_in_group("turnBasedStatusContainer")
	statsReference = {
		"name": statusContainer.name_reference,
		"health": statusContainer.health_reference,
		"maxHealth": statusContainer.max_health_reference,
		"mana": statusContainer.mana_reference,
		"overDrive": statusContainer.over_drive_reference
	}
	
	if not characterResource: return
	
	if statsReference.name in characterResource:
		name_label.text = characterResource[statsReference.name]
	else:
		push_error(statsReference.name + " doesn't found in characterResource")
	
	if statsReference.health in characterResource:
		hp_label_2.text = str(characterResource[statsReference.health])
	else:
		push_error(statsReference.health + " doesn't found in characterResource")
		
	if statsReference.mana in characterResource:
		mp_label_4.text = str(characterResource[statsReference.mana])
	else:
		push_error(statsReference.mana + " doesn't found in characterResource")
		
	if statsReference.maxHealth in characterResource:
		max_hp_2.text = str(characterResource[statsReference.maxHealth])
	else:
		push_error(statsReference.maxHealth + " doesn't found in characterResource")
		
	if statsReference.overDrive in characterResource:
		over_drive_bar.value = characterResource[statsReference.overDrive]
	else:
		push_error(statsReference.overDrive + " doesn't found in characterResource")
	
	health = characterResource[statsReference["health"]]
	mana = characterResource[statsReference["mana"]]
	overDrive = characterResource[statsReference["overDrive"]]
	
	oldCharacterResource = characterResource.duplicate()
	
func _process(delta: float) -> void:
	if not characterResource: 
		push_error("A turn based agent doesn't have set character resource")
		return
		
	var refreshed = _check_refreshed(characterResource, oldCharacterResource)
	
	if refreshed: 
		_update_stats()
		
		health = characterResource[statsReference["health"]]
		mana = characterResource[statsReference["mana"]]
		overDrive = characterResource[statsReference["overDrive"]]

func _check_refreshed(newResource: Resource, oldResource) -> bool:
	var healthChanged = false
	var manaChanged = false
	var overDriveChanged = false
	
	if statsReference["health"] in newResource:
		healthChanged = newResource[statsReference["health"]] != health
	if statsReference["mana"] in newResource:
		manaChanged = newResource[statsReference["mana"]] != mana
	if statsReference["overDrive"] in newResource:
		overDriveChanged = newResource[statsReference["overDrive"]] != overDrive
	
	if healthChanged or manaChanged or overDriveChanged:
		return true
	
	return false
	
func activate_focus() -> void:
	if healMode:
		add_theme_stylebox_override("panel", styleBoxHealFocus)
	else:
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
		
func tween_label(value: int, labelNode: Label) -> void:
	labelNode.text = str(value)

func tween_progress_bar(value: int, progressBarNode: ProgressBar) -> void:
	progressBarNode.value = value

func set_heal_modus(boolean: bool) -> void:
	healMode = boolean
	
	if healMode:
		mp_box.hide()
		hp_max_box.show()
	else:
		mp_box.show()
		hp_max_box.hide()
