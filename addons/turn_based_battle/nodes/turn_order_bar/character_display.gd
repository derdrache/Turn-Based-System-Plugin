extends PanelContainer

var characterName := ""

@onready var label: Label = $VBoxContainer/Label
@onready var texture_rect: TextureRect = $VBoxContainer/TextureRect


var icon: CompressedTexture2D

func _ready() -> void:
	_set_label()
	_set_icon()

	
	
func _set_label():
	if not characterName.is_empty(): return
	
	label.hide()
	label.text = characterName

func _set_icon():
	texture_rect.texture = icon
