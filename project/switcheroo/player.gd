extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

const PROJECTILE_SCENE = preload("res://projectile.tscn")

# --- THE FIX: This creates a checkbox in the Inspector ---
@export var is_controlled: bool = true

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Only lock the mouse if this specific character is being controlled
	if is_controlled:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# Ignore mouse looking if not controlled
	if not is_controlled: 
		return
		
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func _physics_process(delta):
	# Both characters still need gravity and physics processing!
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Only process keyboard inputs if is_controlled is true
	if is_controlled:
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		if Input.is_action_just_pressed("fire"):
			fire_projectile()

		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	else:
		# If it's the dummy, naturally slow down its horizontal movement over time
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		velocity.z = move_toward(velocity.z, 0, SPEED * delta)

	move_and_slide()

func fire_projectile():
	# 1. Instantiate the projectile node structure
	var proj = PROJECTILE_SCENE.instantiate()
	
	# 2. THE CRITICAL FIX: Add it to the tree FIRST so it can accept global space math
	get_tree().current_scene.add_child(proj)
	
	# 3. Spawn it at the PLAYER'S position, lifted up 1 meter (chest height)
	# This prevents it from spawning behind you at the camera
	proj.global_position = global_position + Vector3(0, 1.0, 0)
	
	# 4. Calculate forward direction based on where the camera is looking
	var forward_dir = -camera.global_transform.basis.z.normalized()
	proj.velocity = forward_dir * proj.SPEED
	
	# 5. Assign the launcher reference
	proj.launcher = self
