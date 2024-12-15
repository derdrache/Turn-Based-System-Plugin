extends Button

@export var buttonIcon: CompressedTexture2D

@onready var texture_rect: TextureRect = $MarginContainer/TextureRect

func _ready() -> void:
	texture_rect.texture = buttonIcon
