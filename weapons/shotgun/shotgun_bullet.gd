# shotgun_bullet.gd
extends Area3D

@export var speed: float = 900.0
@export var decay_rate: float = 500.0
@export var speed_threshold: float = 10.0

# Direction is set when spawned
var direction: Vector3 = Vector3.FORWARD
var current_speed: float = 0.0

# @onready var lifetime_timer: Timer = $LifetimeTimer

func _ready():
	# if current_speed == 0:
	# 	current_speed = speed
	body_entered.connect(_on_body_entered)     # Detect collision with physics bodies

func _physics_process(delta: float):
	# Move the bullet forward
	global_position += direction * speed * delta

	# Apply speed decay
	current_speed = max(0.0, current_speed - decay_rate * delta)

	# Check for speed threshold and queue_free if too slow
	if current_speed <= speed_threshold:
		queue_free()

func _on_body_entered(body):
	print("Shotgun Bullet hit: ", body.name)
	# Check if the body hit is an enemy (assuming enemy script is enemy.gd)
	# print("bullet hit smthn that can be harmed", body.has_method("take_damage"))
	if body.has_method("take_damage"): # Add a take_damage method to enemy.gd later
		body.take_damage(10) # Example damage value
	
	# Destroy bullet on impact with anything solid (StaticBody, CharacterBody, RigidBody)
	if body is PhysicsBody3D:
		queue_free()
		
# Function called by weapon to set initial direction
func set_initial_direction(spawn_transform: Transform3D):
	# Set bullet's transform to match muzzle
	self.global_transform = spawn_transform
	# Set movement direction based on forward vector of the transform
	direction = -spawn_transform.basis.z.normalized() # -Z is forward in Godot

# New function called by weapon to set initial speed
func set_initial_speed(initial_speed: float):
	current_speed = initial_speed