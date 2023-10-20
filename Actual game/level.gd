extends Node2D


# Called when the node enters the scene tree for the first time.
func ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	#Plays the audio, and if it stops for some reason, it will start again
	if $Sleepless.playing == false:
		$Sleepless.play()
