extends Button


@export var buttonIcon: CompressedTexture2D

@onready var texture_rect: TextureRect = $MarginContainer/TextureRect

func _ready() -> void:
	texture_rect.texture = buttonIcon


func _on_pressed() -> void:
	var turnBasedController: TurnBasedController = get_tree().get_first_node_in_group("turnBasedController")
