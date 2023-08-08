extends CharacterBody2D
class_name Player


@export var speed : float = 300.0
@export var jump_velocity : float = -400.0
@export var gravity : float = 1500
@export var swim_gravity_factor : float = 0.25
@export var swim_velocity_cap : float = 50.0
var motion = Vector2()

#for losing abilities and winning
var canJump = 1
var cancanDash = 1
var canClimb = 1
var canDoubleJump = 1
@export var number_of_items = 0

#needed for double jump
var has_double_jumped : bool = false
#Variables for dashing
var dashDirection = Vector2(1, 0)
var canDash : bool = false
var dashing : bool = false

#needed for the grappling hook
var hook_pos = Vector2()
var hooked = false
var rope_length = 500
var current_rope_length

#For interactions
@onready var all_interactions = []
@onready var interactLable = $"Interaction Components/InteractLabel"

#for swimming
var is_in_water : bool = false

#spikes
var has_hit_spike : bool = false



func gain_ability(ability):
	if ability  > 1:
		ability = 0
	if ability == 1:
		number_of_items += 1
	else:
		number_of_items -= 1

  
func _physics_process(delta):
	#calls the other functions
	wall_right()
	wall_left()
	queue_redraw()
	update_interactions()
	flip_gravity()
	
	#should try to make a function for this, but when I did it didn't work. Come back to
	if canJump > 1:
		canJump = 0
	if cancanDash > 1:
		cancanDash = 0
	if canClimb > 1:
		canClimb = 0
	if canDoubleJump > 1:
		canDoubleJump = 0
	

	
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
	else:
		has_double_jumped = false

	# Jumping code.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() and canJump == 1 and gravity == 1500:
			#single jump
				velocity.y = jump_velocity
		elif is_on_ceiling() and canJump == 1:
			velocity.y = jump_velocity
		elif (!has_double_jumped) and canDoubleJump == 1:
			#code for double jump
			velocity.y = jump_velocity
			has_double_jumped = true
			
	#code for the wall climb	
	if canClimb == 1:
		if wall_left() == true or wall_right() == true:
			velocity.y = 5000 * delta
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
	if is_on_floor():
		canDash = true
	
	if cancanDash == 0 and canClimb == 0 and canDoubleJump == 0:
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
	
func draw():
	var _pos = global_position
	
	if hooked: 
		draw_line(Vector2(0,0), to_local(hook_pos), Color(0.35, 0.7, 0.9), 3, true)#cyan colour
	else:
		
		var colliding = $GrapplingRayCasts.is_colliding()
		var collide_point = $GrapplingRayCasts.get_collision_point()
		if colliding and _pos.distance_to(collide_point) < rope_length:
			draw_line(Vector2(0,0), to_local(collide_point), Color(1,1,1,0.25), 0.5, true)#white colour
			
func swing(delta):
	var radius = global_position - hook_pos
	if motion.length() < 0.01 or radius.length < 10: return
	var angle = acos(radius.dot(motion) / (radius.length() * motion.lenght()))
	var rad_vel = cos(angle) * motion.length()
	motion += radius.normalized() * -rad_vel
	
	if global_position.distance_to(hook_pos) > current_rope_length:
		global_position = hook_pos + radius.normalized() * current_rope_length
	
	motion += (hook_pos - global_position).normalized() * 15000 * delta




  

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
			"jumping" : canJump += 1
			"dashing" : cancanDash += 1
			"climbing" : canClimb += 1
			"doublejumping" : canDoubleJump += 1


#code for swimming
func _on_water_detection_2d_water_state_changed(is_in_water : bool):
	self.is_in_water = is_in_water
	print(is_in_water)
	
func _spike_detection(has_hit_spike : bool):
	self.has_hit_spike = has_hit_spike
	print("yo")
	
func flip_gravity():
	#flip gravity
	if Input.is_action_just_pressed("flip"):
		gravity *= -1
		swim_gravity_factor *= -1
		jump_velocity *= -1
		motion *= -1
		if is_on_ceiling():
			has_double_jumped = false
