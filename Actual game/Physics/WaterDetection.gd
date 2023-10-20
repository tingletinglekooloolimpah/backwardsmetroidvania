extends Area2D

signal water_state_changed(is_in_water : bool)

var is_in_water : bool = false;#variables for when the player is in the water

func _on_body_entered(_body):#player enters the water
	if(is_in_water == false):
		var overlapping_bodies = get_overlapping_bodies() 
	
		if(overlapping_bodies.size() >= 1):
			is_in_water = true
			emit_signal("water_state_changed", is_in_water)

func _on_body_exited(_body):#means player exits the water
	var overlapping_bodies = get_overlapping_bodies() 
	
	if(overlapping_bodies.size() == 0):
		is_in_water = false
		emit_signal("water_state_changed", is_in_water)
