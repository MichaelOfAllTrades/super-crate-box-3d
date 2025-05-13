# bazooka_bullet.gd
extends Area3D

@export var speed: float = 900.0
# Direction is set when spawned
var direction: Vector3 = Vector3.FORWARD

# @onready var lifetime_timer: Timer = $LifetimeTimer

# Reference to explosion scene
@export var explosion_scene: PackedScene

func _ready():
	# Connect signals
	#lifetime_timer.timeout.connect(queue_free) # Remove bullet when timer ends
	body_entered.connect(_on_body_entered)     # Detect collision with physics bodies

func _physics_process(delta: float):
	# Move the bullet forward
	global_position += direction * speed * delta

func _on_body_entered(body):
	print("Bazooka Bullet hit: ", body.name)
	#print("Bullet hit: ", body.name)
	# Check if the body hit is an enemy (assuming enemy script is enemy.gd)
	# print("bullet hit smthn that can be harmed", body.has_method("take_damage"))
	if body.has_method("take_damage"): # Add a take_damage method to enemy.gd later
		body.take_damage(10) # Example damage value

	# Create explosion effect
	if explosion_scene:
		var explosion_instance = explosion_scene.instantiate()
		get_tree().root.add_child(explosion_instance)
		explosion_instance.global_position = global_position # Set explosion position to bullet's position
		# explosion_instance.queue_free() # Optionally free the explosion instance after use
		queue_free()

	# Destroy bullet on impact with anything solid (StaticBody, CharacterBody, RigidBody)
	if body is PhysicsBody3D:
		queue_free()

# Function called by weapon to set initial direction
func set_initial_direction(spawn_transform: Transform3D):
	# Set bullet's transform to match muzzle
	self.global_transform = spawn_transform
	# Set movement direction based on forward vector of the transform
	direction = -spawn_transform.basis.z.normalized() # -Z is forward in Godot