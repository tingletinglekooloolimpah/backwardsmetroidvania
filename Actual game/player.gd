extends CharacterBody2D
class_name Player


@export var speed : float = 300.0
@export var jump_velocity : float = -400.0
@export var gravity : float = 1500
@export var swim_gravity_factor : float = 0.25
@export var swim_velocity_cap : float = 50.0
var motion = Vector2()

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D

#for losing abilities and winning
var canDash = 1
var canClimb = 0
var canDoubleJump = 1
var canFlip = 0
var canSwim = 1
var canLight = 0
var canMorph = 0

#needed for double jump
var has_double_jumped : bool = false
#Variables for dashing
var dashDirection = Vector2(1, 0)
var dashPossible : bool = false
var dashing : bool = false

#For interactions
@onready var all_interactions = [] 
@onready var interactLabel = $"Interaction Components/InteractLabel"
@onready var spawn_pos = []
var can_interact = true
#for swimming
var is_in_water : bool = false

func _ready():
	update_interactions()
	
func _physics_process(delta):
	update_interactions()
	if can_interact == true:
		#calls the other functions
		wall_right()
		wall_left()
		flip_gravity()
		squash_and_stretch()
		y_direction()
		light()
		
		#should try to make a function for this, but when I did it didn't work. Come back to
		if canDash > 1:
			canDash = 0
		if canClimb > 1:
			canClimb = 0
		if canDoubleJump > 1:
			canDoubleJump = 0
		if canFlip > 1:
			canFlip = 0
		if canSwim > 1:
			canSwim = 0
		if canLight > 1:
			canLight = 0
		if canMorph > 1:
			canMorph = 0

		
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
		if is_on_floor() and is_in_water: #this means you won't stick to the floor if you are in water. removing the if not is_on_floor does weird things
			if Input.is_action_pressed("up"):
					velocity.y = -speed * 0.5

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
		if canClimb == 1 and $StretchCollision2D.disabled == true and $SquashCollision2D.disabled == true and (!is_in_water):
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
		
		if Input.is_action_just_pressed("dash") and canDash == 1:
			dash()
		if (is_on_floor() and gravity > 0) or (is_on_ceiling() and gravity < 0):
			dashPossible = true
		
		if canDash == 0 and canClimb == 0 and canDoubleJump == 0 and canFlip == 0 and canSwim == 0 and canLight == 0 and canMorph == 0:
			get_tree().change_scene_to_file("res://menus/win_screen.tscn")
		
		
		move_and_slide()

#code for dash
func dash():
	if dashPossible:
		if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
			velocity = dashDirection.normalized() * 5000
		else:
			velocity = dashDirection.normalized() * 2500
		dashPossible = false
		dashing = true
		await get_tree().create_timer(1.0).timeout
		dashing = false

#needed for climbing
func wall_right():
	return $Walls/RightWall.is_colliding()

func wall_left():
	return $Walls/LeftWall.is_colliding()
  

#Interaction Methods
################################################################################

func _on_interaction_area_area_entered(area):
	all_interactions.insert(0, area)
	spawn_pos.clear()
	spawn_pos.insert(0, position.x)
	spawn_pos.insert(1, position.y)
	update_interactions()


func _on_interaction_area_area_exited(area):
	all_interactions.erase(area)
	update_interactions()
	
func update_interactions():
	if all_interactions:
		interactLabel.text = all_interactions[0].interact_label
	else:
		interactLabel.text = ""

		
func execute_interaction():
	if all_interactions:
		var cur_interaction = all_interactions[0]
		match cur_interaction.interact_type:
			"dashing" : canDash += 1
			"climbing" : canClimb += 1
			"doublejumping" : canDoubleJump += 1
			"swimming" : canSwim += 1
			"flipping" : canFlip += 1
			"lighting" : canLight += 1
			"morphing" : canMorph += 1
			"change_gravity" : if canFlip == 1:
				print(canFlip)
				gravity *= -1
				jump_velocity *= -1
				swim_velocity_cap *= -1
				if (!is_on_ceiling() and (!is_on_floor())):
					can_interact = false 
				else:
					can_interact = true #make death animation so this doesn't seem so jarringf
				


#code for swimming
@warning_ignore("shadowed_variable")
func _on_water_detection_2d_water_state_changed(is_in_water):
	if canSwim == 1:
		self.is_in_water = is_in_water
	else:
		position.x = spawn_pos[0]
		position.y = spawn_pos[1]
		can_interact = false
		await get_tree().create_timer(0.8).timeout 
		can_interact = true #make death animation so this doesn't seem so jarring
		
func flip_gravity():
	if (is_on_ceiling() and gravity < 0) or (is_on_floor() and gravity > 0):
			has_double_jumped = false
	if gravity < 0 and is_on_floor() and (!is_in_water):
		velocity.y = -jump_velocity * 0.1

func y_direction():
	if gravity < 0:
		animated_sprite.flip_v = true
	elif gravity > 0:
		animated_sprite.flip_v = false
		
func squash_and_stretch():
	if (!is_in_water):
		if Input.is_action_pressed("down") and canMorph == 1:
			$SquashCollision2D.disabled = false
			$NormalCollision2D.disabled = true
			$StretchCollision2D.disabled = true
			animated_sprite.play("squash")
		elif Input.is_action_pressed("up") and canMorph == 1:
			$SquashCollision2D.disabled = true
			$NormalCollision2D.disabled = true
			$StretchCollision2D.disabled = false
			animated_sprite.play("stretch")
		else:
			$SquashCollision2D.disabled = true
			$NormalCollision2D.disabled = false 
			$StretchCollision2D.disabled = true
			animated_sprite.play("idle")
			
func light():
	if canLight == 1:
		$Lighting.show()
	else:
		$Lighting.hide()
