extends Control


# Called when the node enters the scene tree for the first time.
func _ready(): 
	$VBoxContainer/StartButton.grab_focus()

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://level.tscn")#lets the player play the game 

func _on_controls_button_pressed():
	get_tree().change_scene_to_file("res://menus/controls.tscn")#changes to control menu


func _on_exit_button_pressed():
	get_tree().quit()#quits the application
