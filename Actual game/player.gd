extends CharacterBody2D
class_name Player


@export var speed : float = 300.0
@export var jump_velocity : float = -400.0
@export var gravity : float = 1500
@export var swim_gravity_factor : float = 0.25
@export var swim_velocity_cap : float = 50.0
var motion = Vector2()


#for losing abilities and winning
var cancanDash = 1
var canClimb = 1
var canDoubleJump = 1
var canFlip = 1
var canSwim = 1

#needed for double jump
var has_double_jumped : bool = false
#Variables for dashing
var dashDirection = Vector2(1, 0)
var canDash : bool = false
var dashing : bool = false

#For interactions
@onready var all_interactions = []
@onready var interactLable = $"Interaction Components/InteractLabel"

#for swimming
var is_in_water : bool = false



  
func _physics_process(delta):
	#calls the other functions
	wall_right()
	wall_left()
	update_interactions()
	flip_gravity()
	
	#should try to make a function for this, but when I did it didn't work. Come back to
	if cancanDash > 1:
		cancanDash = 0
	if canClimb > 1:
		canClimb = 0
	if canDoubleJump > 1:
		canDoubleJump = 0
	if canFlip > 1:
		canFlip = 0
	if canSwim > 1:
		canSwim = 0
	

	
	if Input.is_action_just_pressed("interact"): #This allows the code to do contact sensative actions
		execute_interaction()
		
	# Add the gravity.
	if not is_on_floor():
		if(!is_in_water):
			velocity.y += gravity * delta
		else:
			if Input.is_action_pressed("up"):
				velocity.y = -speed * 0.5
			elif Input.is_action_pressed("down"):
				velocity.y = speed * 0.5
			else:
				velocity.y = clampf(velocity.y + (gravity * delta * swim_gravity_factor), swim_velocity_cap, swim_velocity_cap)


	# Jumping code.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() and gravity > 0:
			#single jump
				velocity.y = jump_velocity
		elif is_on_ceiling() and gravity < 0: #double jump doesn't work without it for some reason
			velocity.y = jump_velocity
		elif (!has_double_jumped) and canDoubleJump == 1:
			#code for double jump
			velocity.y = jump_velocity
			has_double_jumped = true
			
	#code for the wall climb	
	if canClimb == 1:
		if wall_left() == true or wall_right() == true:
			velocity.y = 5000 * delta * gravity/abs(gravity)
			if wall_left() == true and Input.is_action_pressed("left"):	
				velocity.x = 1000
				velocity.y = jump_velocity * 0.4
				has_double_jumped = false
			if wall_right() == true and Input.is_action_pressed("right"):	
				velocity.x = -1000
				velocity.y = jump_velocity * 0.4
				has_double_jumped = false
			
	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	#code for dashing inside the physics process	
	if Input.is_action_pressed("left"):
		dashDirection = Vector2(-1, 0)
	if Input.is_action_pressed("right"):
		dashDirection = Vector2(1, 0)
	
	if Input.is_action_just_pressed("dash") and cancanDash == 1:
		dash()
	if (is_on_floor() and gravity > 0) or (is_on_ceiling() and gravity < 0):
		canDash = true
	
	if cancanDash == 0 and canClimb == 0 and canDoubleJump == 0 and canFlip == 0 and canSwim == 0:
		get_tree().change_scene_to_file("res://menus/win_screen.tscn")
	
	move_and_slide()

#code for dash
func dash():
	if canDash:
		if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
			velocity = dashDirection.normalized() * 5000
		else:
			velocity = dashDirection.normalized() * 2000
		canDash = false
		dashing = true
		await get_tree().create_timer(1.0).timeout
		dashing = false

#needed for climbing
func wall_right():
	return $RightWall.is_colliding()	

func wall_left():
	return $LeftWall.is_colliding()



  

#Interaction Methods
################################################################################

func _on_interaction_area_area_entered(area):
	all_interactions.insert(0, area)
	update_interactions()


func _on_interaction_area_area_exited(area):
	all_interactions.erase(area)
	update_interactions()
	
func update_interactions():
	if all_interactions:
		interactLable.text = all_interactions[0].interact_label
	else:
		interactLable.text = ""

		
func execute_interaction():
	if all_interactions:
		var cur_interaction = all_interactions[0]
		match cur_interaction.interact_type:
			"dashing" : cancanDash += 1
			"climbing" : canClimb += 1
			"doublejumping" : canDoubleJump += 1
			"swimming" : canSwim += 1
			"flipping" : canFlip += 1


#code for swimming
func _on_water_detection_2d_water_state_changed(is_in_water : bool):
	if canSwim == 1:
		self.is_in_water = is_in_water
	else:
		print("position = spawn_pos")

func flip_gravity():
	#flip gravity
	if Input.is_action_just_pressed("flip") and canFlip ==  1:
		gravity *= -1
		jump_velocity *= -1 
	if (is_on_ceiling() and gravity < 0) or (is_on_floor() and gravity > 0):
			has_double_jumped = false
	if gravity < 0 and is_on_floor():
		velocity.y = -jump_velocity * 0.2
