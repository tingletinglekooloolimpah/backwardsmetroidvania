extends Area2D

signal spike_state_changed(has_hit_spike : bool)

var has_hit_spike : bool = false;

func _on_body_entered(body):
	if (has_hit_spike == false):
		var overlapping_bodies = get_overlapping_bodies()
		
		if(overlapping_bodies.size()>= 1):
			has_hit_spike = true
			emit_signal("spike_state_changed", has_hit_spike)
			
func _on_body_exited(body):
	var overlapping_bodies = get_overlapping_bodies() 
	
	if(overlapping_bodies.size() == 0):
		has_hit_spike = false
		emit_signal("spike_state_changed", has_hit_spike)
