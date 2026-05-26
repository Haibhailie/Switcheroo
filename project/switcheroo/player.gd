extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003
const VOID_HEIGHT = -10.0

const PROJECTILE_SCENE = preload("res://projectile.tscn")

@export var is_controlled: bool = true

# --- PERSPECTIVE VARIABLES ---
var is_fpp: bool = true
@onready var mesh_instance = $MeshInstance3D
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

# --- NEW: GAME ECONOMY VARIABLES ---
@export var max_ammo: int = 3
var current_ammo: int = max_ammo
var is_reloading: bool = false
var reload_time: float = 1.2
var reload_timer: float = 0.0

var score: int = 0

# --- NEW: UI REFERENCES ---
@onready var player_ui = $PlayerUI
@onready var score_label = $PlayerUI/ScoreLabel
@onready var ammo_label = $PlayerUI/AmmoLabel

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var spawn_position: Vector3

func _ready():
	spawn_position = global_position
	
	if is_controlled:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		update_ui()
	else:
		# THE FIX: If this is the dummy clone, completely delete its UI 
		# layer so it doesn't render text over the real player's monitor.
		player_ui.queue_free()

func _unhandled_input(event):
	if not is_controlled: 
		return
		
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	check_void_fall()

	# Handle the passive reload countdown timer
	if is_reloading:
		reload_timer -= delta
		ammo_label.text = "Reloading... " + str(snapped(reload_timer, 0.1)) + "s"
		if reload_timer <= 0.0:
			current_ammo = max_ammo
			is_reloading = false
			update_ui()

	if is_controlled:
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Shooting verification logic
		if Input.is_action_just_pressed("fire"):
			if current_ammo > 0 and not is_reloading:
				fire_projectile()
				current_ammo -= 1
				update_ui()
			elif current_ammo == 0 and not is_reloading:
				start_reload()

		# Manual Reload execution
		if Input.is_action_just_pressed("reload") and current_ammo < max_ammo and not is_reloading:
			start_reload()

		if Input.is_action_just_pressed("toggle_view"):
			is_fpp = !is_fpp
			if is_fpp:
				camera.position = Vector3.ZERO
				mesh_instance.visible = false
			else:
				camera.position = Vector3(0, 0, 3.0)
				mesh_instance.visible = true

		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		velocity.z = move_toward(velocity.z, 0, SPEED * delta)

	move_and_slide()

func start_reload():
	is_reloading = true
	reload_timer = reload_time

func update_ui():
	if score_label and ammo_label:
		score_label.text = "Score: " + str(score)
		ammo_label.text = "Ammo: " + str(current_ammo) + " / " + str(max_ammo)

func add_score(amount: int):
	score += amount
	update_ui()

func check_void_fall():
	if global_position.y < VOID_HEIGHT:
		global_position = spawn_position
		velocity = Vector3.ZERO
		
		# If the dummy drops into the abyss, find the real player and give them a point!
		if not is_controlled:
			var player_node = get_tree().current_scene.get_node_or_null("Player")
			if player_node and player_node.has_method("add_score"):
				player_node.add_score(1)

func fire_projectile():
	var proj = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.launcher = self

	if is_fpp:
		proj.global_position = camera.global_position
		var forward_dir = -camera.global_transform.basis.z.normalized()
		proj.velocity = forward_dir * proj.SPEED
	else:
		proj.global_position = global_position + Vector3(0, 1.0, 0)
		
		var space_state = get_world_3d().direct_space_state
		var mouse_position = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_position)
		var ray_end = ray_origin + camera.project_ray_normal(mouse_position) * 100.0
		
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.exclude = [self.get_rid()]
		
		var result = space_state.intersect_ray(query)
		
		var target_point: Vector3
		if result:
			target_point = result.position
		else:
			target_point = ray_end

		var direction = (target_point - proj.global_position).normalized()
		proj.velocity = direction * proj.SPEED
