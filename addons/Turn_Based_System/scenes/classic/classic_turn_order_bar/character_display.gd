@icon("res://addons/Turn_Based_System/assets/icons/VBoxContainer.svg")
extends PanelContainer

@onready var texture_rect: TextureRect = $VBoxContainer/TextureRect

var icon: CompressedTexture2D

func _ready() -> void:
	_setup_icon()

func _setup_icon() -> void:
	if icon: texture_rect.texture = icon
