extends Area3D

# How high the pad launches the player
@export var launch_force: float = 15.0

func _ready():
	# Connect the engine's body_entered signal to our launch function
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check if the thing that stepped on us has a velocity property (like our mages)
	if "velocity" in body:
		# 1. Force their vertical upward speed to our launch force
		body.velocity.y = launch_force
		
		# 2. (Optional visual flair) Scale the pad down and up slightly to make it "boing"
		var tween = create_tween()
		tween.tween_property(self, "scale:y", 0.5, 0.05)
		tween.tween_property(self, "scale:y", 1.0, 0.1)
