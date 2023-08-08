extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$EscapeButton.grab_focus()



func _on_escape_pressed():
	get_tree().change_scene_to_file("res://menus/menu.tscn")
