# bullet.gd
extends Area3D

@export var speed: float = 900.0
# Direction is set when spawned
var direction: Vector3 = Vector3.FORWARD 

# @onready var lifetime_timer: Timer = $LifetimeTimer

# References to child nodes (assigned in _ready)
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready():
	# Connect signals
	#lifetime_timer.timeout.connect(queue_free) # Remove bullet when timer ends
	body_entered.connect(_on_body_entered)     # Detect collision with physics bodies
	_update_dimensions()

func _update_dimensions():
	# print("bullet getting resized")
	# print("bullet ", mesh_instance)
	# print("bullet ", mesh_instance.mesh is SphereMesh)
	# print("bullet ", collision_shape)
	# print("bullet ", collision_shape.shape is SphereShape3D)
	if mesh_instance and mesh_instance.mesh is SphereMesh and collision_shape and collision_shape.shape is SphereShape3D:
		var curr_mesh = mesh_instance.mesh
		if curr_mesh is SphereMesh:
			var unique_mesh = curr_mesh.duplicate() as SphereMesh
			unique_mesh.radius = GameConfig.pistol_bullet_size
			unique_mesh.height = GameConfig.pistol_bullet_size * 2.0
			mesh_instance.mesh = unique_mesh
		var curr_shape = collision_shape.shape
		if curr_shape is SphereShape3D:
			var unique_shape = curr_shape.duplicate() as SphereShape3D
			unique_shape.radius = GameConfig.pistol_bullet_size
			collision_shape.shape = unique_shape

func _physics_process(delta: float):
	# Move the bullet forward
	global_position += direction * speed * delta

func _on_body_entered(body):
	# print("regular Bullet hit: ", body.name)
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
