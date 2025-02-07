extends Button

@export var buttonIcon: CompressedTexture2D
@export var command: CommandResource

@onready var texture_rect: TextureRect = %TextureRect
@onready var texture_rect_container: MarginContainer = %TextureRectContainer
@onready var command_name_label: Label = %CommandNameLabel
@onready var mana_cost_label: Label = %manaCostLabel
@onready var mana_cost_container: MarginContainer = %manaCostContainer

func _ready() -> void:
	var turnBasedController: TurnBasedController = get_tree().get_first_node_in_group("turnBasedController")
	texture_rect_container.hide()
	mana_cost_container.hide()
	
	if buttonIcon:
		texture_rect.texture = buttonIcon
		texture_rect_container.show()
	
	if command and command.manaCost:
		mana_cost_label.text = str(command.manaCost)
		mana_cost_container.show()
		
		var currentMana = turnBasedController.get_active_character().characterResource.currentMana
		if command.manaCost > currentMana:
			mana_cost_label.add_theme_color_override("font_color", Color.RED)
			
	if command and not command.isAllowed:
		command_name_label.add_theme_color_override("font_color", Color.GRAY)
		mana_cost_label.add_theme_color_override("font_color", Color.GRAY)

func set_name(name:String):
	%CommandNameLabel.text = name
