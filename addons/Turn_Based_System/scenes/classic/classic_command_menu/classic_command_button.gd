extends Button

@export var buttonIcon: CompressedTexture2D
@export var command: CommandResource

@onready var texture_rect: TextureRect = %TextureRect
@onready var texture_rect_container: MarginContainer = %TextureRectContainer

@onready var mana_cost_label: Label = %manaCostLabel
@onready var mana_cost_container: MarginContainer = %manaCostContainer

func _ready() -> void:
	texture_rect_container.hide()
	mana_cost_container.hide()
	
	if buttonIcon:
		texture_rect.texture = buttonIcon
		texture_rect_container.show()
		
	if command:
		mana_cost_label.text = str(command.manaCost)
		mana_cost_container.show()

func set_name(name:String):
	%CommandNameLabel.text = name
