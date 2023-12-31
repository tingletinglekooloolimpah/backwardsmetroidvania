extends CharacterBody2D
class_name Player

#physics variables
@export var speed : float = 300.0
@export var jump_velocity : float = -400.0
@export var gravity : float = 1500
@export var swim_gravity_factor : float = 0.25
@export var swim_velocity_cap : float = 50.0
#double jump, jump buffer and cayote time variables
@export var jump_counter : int = 0
@export var jump_buffer_time : float = 15.0
@export var jump_buffer_counter : int = 0
@export var cayote_time: float = 15.0
@export var cayote_counter : int = 0
var motion = Vector2()

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D #means sprite can be animated

#these control whether the player has the abilities or not
var canDash = 1
var canClimb = 1
var canDoubleJump = 1
var canFlip = 1
var canSwim = 1
var canLight = 0
var canMorph = 1


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
		escape()
		
		#this makes the player lose an ability if they already have it
		if canDash > 1:
			canDash = 0
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
		if canClimb > 1:
			canClimb = 0
			

		if Input.is_action_just_pressed("interact"): 
			execute_interaction()#Allows contact sensative actions
		
		if (gravity > 0 and is_on_floor()) or (gravity < 0 and is_on_ceiling()): 
			cayote_counter = cayote_time
			jump_counter = 0
			
		if (gravity > 0 and (!is_on_floor())) or (gravity < 0 and (!is_on_ceiling())):
			if cayote_counter > 0:
				cayote_counter -= 1#gives player 15 frames for cayote time
			if jump_buffer_counter > 0 and jump_counter < 1:
				cayote_counter = 1
				jump_counter += 1
				
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
					velocity.y = clampf(velocity.y + (gravity * delta * swim_gravity_factor), 
					swim_velocity_cap, swim_velocity_cap)
		if is_on_floor() and is_in_water: #means you won't stick to the floor if you are in water
			if Input.is_action_pressed("up"):
					velocity.y = -speed * 0.5

		# Jumping code.
		if Input.is_action_just_pressed("jump"):
			jump_buffer_counter = jump_buffer_time
		if jump_buffer_counter > 0: #Jump buffer lets the player jump 15 frames before landing
			jump_buffer_counter -= 1
		if jump_buffer_counter > 0 and cayote_counter > 0:
			#single jump
			velocity.y = jump_velocity
			jump_buffer_counter = 0
			cayote_counter = 0
			
		if Input.is_action_just_released("jump"): # variable jump height
			if velocity.y < 0:
				velocity.y += 100 #value that felt best for more testers
				
		#code for the wall climb
		if canClimb == 1 and $StretchCollision2D.disabled == true and (!is_in_water):
				if wall_left() == true or wall_right() == true:
					velocity.y = 5000 * delta * gravity/abs(gravity)
					if wall_left() == true and Input.is_action_pressed("left"):	
						velocity.x = 1000
						velocity.y = jump_velocity * 0.4 #Makes you jump onto the wall
						jump_counter = 0
					if wall_right() == true and Input.is_action_pressed("right"):	
						velocity.x = -1000
						velocity.y = jump_velocity * 0.4 #Makes you jump onto the wall
						jump_counter = 0

		if is_in_water and (Input.is_action_pressed("jump") or Input.is_action_pressed("down")):
			$StretchCollision2D.disabled = true
			animated_sprite.play("idle")


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
		
		if canDash == 0 and canClimb == 0 and canDoubleJump == 0 and canFlip == 0:
			if canSwim == 0 and canLight == 0 and canMorph == 0:
				get_tree().change_scene_to_file("res://menus/win_screen.tscn")#changes to winscreen
		
			
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

#Climbs walls
func wall_right():
	return $Walls/RightWall.is_colliding()

func wall_left():
	return $Walls/LeftWall.is_colliding()
  

#Interaction Methods
################################################################################

func _on_interaction_area_area_entered(area):#Updates the list once the player needs that info
	all_interactions.insert(0, area)
	spawn_pos.clear()
	spawn_pos.insert(0, position.x)
	spawn_pos.insert(1, position.y)
	update_interactions()


func _on_interaction_area_area_exited(area):#gets rid of anything in the list once it isn't needed
	all_interactions.erase(area)
	update_interactions()
	
func update_interactions():
	if all_interactions:
		interactLabel.text = all_interactions[0].interact_label #changes what text is above player
	else:
		interactLabel.text = "" #makes no text when there is no text to show

		
func execute_interaction():
	if all_interactions:
		var cur_interaction = all_interactions[0]
		match cur_interaction.interact_type:
			"dashing" : canDash += 1 #changes whether the player can use these abilities
			"climbing" : canClimb += 1
			"swimming" : canSwim += 1
			"flipping" : canFlip += 1
			"lighting" : canLight += 1
			"morphing" : canMorph += 1
			"doublejumping" : canDoubleJump += 1
			"change_gravity" : if canFlip == 1:
				gravity *= -1 #these variables change the gravity
				jump_velocity *= -1
				swim_velocity_cap *= -1
				if (!is_on_ceiling() and (!is_on_floor())):
					can_interact = true 
				else:
					can_interact = true 
				

func swap_boolean(variable):
	if variable == true:
		variable = false
	if variable  == false:
		variable = true

#code for swimming
func _on_water_detection_2d_water_state_changed(is_in_water):
	if canSwim == 1:
		self.is_in_water = is_in_water #if they are in the water they can swim
	else:
		position.x = spawn_pos[0] #puts the player back to their last interactable component
		position.y = spawn_pos[1]
		can_interact = false
		await get_tree().create_timer(0.8).timeout 
		can_interact = true #make death animation so this doesn't seem so jarring
		
func flip_gravity(): #Flips the gravity
	if (is_on_ceiling() and gravity < 0) or (is_on_floor() and gravity > 0):
		jump_counter = 1 #Rewritten the code so you can doublejump while on ceiling and floor
	if gravity < 0 and is_on_floor() and (!is_in_water):
		velocity.y = -jump_velocity * 0.1 #Flips the jump velocity you jump downwards if on ceiling

func y_direction(): #This flips my character sprite when the gravity is flipped
	if gravity < 0:
		animated_sprite.flip_v = true
	elif gravity > 0:
		animated_sprite.flip_v = false
		
func squash_and_stretch():
	if (!is_in_water):
		if Input.is_action_pressed("up") and canMorph == 1:
			$NormalCollision2D.disabled = true#changes the collision shape for the sprite
			$StretchCollision2D.disabled = false
			animated_sprite.play("stretch")
		else:
			$NormalCollision2D.disabled = false 
			$StretchCollision2D.disabled = true
			animated_sprite.play("idle")
			
func light():
	if canLight == 1:
		$Lighting.show()
	else:
		$Lighting.hide()

func escape(): #allows player to go back to the menu
	if Input.is_action_pressed("escape"):
			get_tree().change_scene_to_file("res://menus/menu.tscn")
