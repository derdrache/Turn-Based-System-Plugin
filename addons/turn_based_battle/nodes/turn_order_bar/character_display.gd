extends PanelContainer

@export var characterName := ""

@onready var label: Label = $VBoxContainer/Label



func _ready() -> void:
	if characterName.is_empty(): label.hide()

	label.text = characterName
