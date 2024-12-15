extends Node

func _process(_delta):
	if Input.is_action_just_pressed("ui_end"):
		var image = get_viewport().get_texture().get_image()
		image.save_png("res://screenshot.png")
