@icon("res://addons/Turn_Based_System/assets/icons/VBoxContainer.svg")
extends PanelContainer

var characterName := ""

@onready var label: Label = $VBoxContainer/Label
@onready var texture_rect: TextureRect = $VBoxContainer/TextureRect


var icon: CompressedTexture2D

func _ready() -> void:
	_setup_label()
	_setup_icon()
	
func _setup_label():
	if not characterName.is_empty(): return
	
	label.hide()
	label.text = characterName

func _setup_icon():
	texture_rect.texture = icon
