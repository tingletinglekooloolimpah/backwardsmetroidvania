extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$ReturnButton.grab_focus()




func _on_button_pressed():
	get_tree().change_scene_to_file("res://menus/menu.tscn")#changes to main menu
