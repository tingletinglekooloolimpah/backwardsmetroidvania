extends CharacterBody2D


@export var  speed = 300.0
@export var  jump_velocity = -400.0
@export var gravity = 1500

#needed for double jump
var has_double_jumped : bool = false
#Variables for dashing
var dashDirection = Vector2(1, 0)
var canDash : bool = false
var dashing : bool = false

func _physics_process(delta):
	#calls the other functions
	dash()
	wall_right()
	wall_left()
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		has_double_jumped = false

	# Jumping code.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			#single jump
			velocity.y = jump_velocity
		elif not has_double_jumped:
			#code for double jump
			velocity.y = jump_velocity
			has_double_jumped = true
			
	#code for the wall climb	
	if wall_left() == true or wall_right() == true:
		velocity.y = 1000 * delta
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

	move_and_slide()

#code for dash
func dash():
	if is_on_floor():
		canDash = true
	
	if Input.is_action_pressed("left"):
		dashDirection = Vector2(-1, 0)
	if Input.is_action_pressed("right"):
		dashDirection = Vector2(1, 0)
		
	if Input.is_action_just_pressed("dash") and canDash:
		velocity = dashDirection.normalized() * 2000
		canDash = false
		dashing = true
		await get_tree().create_timer(0.1).timeout
		dashing = false

func wall_right():
	return $RightWall.is_colliding()
	
func wall_left():
	return $LeftWall.is_colliding()
