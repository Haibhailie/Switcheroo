extends Area3D

const SPEED = 30.0
var velocity = Vector3.ZERO
var launcher: CharacterBody3D = null # We store who shot it so you don't swap with yourself

func _ready():
	# Connect the engine's body_entered signal to our custom collision function
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Move forward based on where the projectile is facing
	global_position += velocity * delta

func _on_body_entered(body):
	# Ignore collisions with the person who shot it or the floor
	if body == launcher or body.name == "CSGBox3D":
		return
		
	# Check if we hit something that can move (like our DummyTarget)
	if body is CharacterBody3D:
		# --- THE SWAP LOGIC ---
		# 1. Grab both positions
		var pos_a = launcher.global_position
		var pos_b = body.global_position
		
		# 2. Grab both velocities (momentum)
		var vel_a = launcher.velocity
		var vel_b = body.velocity
		
		# 3. Swap positions
		launcher.global_position = pos_b
		body.global_position = pos_a
		
		# 4. Swap velocities
		launcher.velocity = vel_b
		body.velocity = vel_a
		
	# Destroy the projectile after impact
	queue_free()
