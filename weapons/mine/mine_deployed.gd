# MineDeployed.gd
extends Area3D

# Assign your Explosion scene in the inspector
@export var explosion_scene: PackedScene 
# Optional: if mines can hurt the player too
# @export var damage_player: bool = false 

var is_active: bool = false

@onready var activation_timer: Timer = $ActivationTimer

# References to child nodes (assigned in _ready)
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready():
	_update_dimensions()
	# Connect the body_entered signal to a method
	body_entered.connect(_on_body_entered)
	# Example: if you add a Timer for lifespan
	# $Timer.timeout.connect(explode) # Assuming Timer node is named "Timer"
	# $Timer.start()
	activation_timer.wait_time = GameConfig.MINE_ACTIVATION_DELAY
	activation_timer.one_shot = true
	activation_timer.timeout.connect(_on_activation_timer_timeout)
	activation_timer.start()

func _update_dimensions():
	if mesh_instance and mesh_instance.mesh is CylinderMesh and collision_shape and collision_shape.shape is CylinderShape3D:
		var new_size = Vector3(GameConfig.MINE_RADIUS, GameConfig.MINE_HEIGHT, GameConfig.MINE_RADIUS)
		mesh_instance.mesh.size = new_size
		collision_shape.shape.size = new_size

func _on_activation_timer_timeout():
	is_active = true

func _on_body_entered(body: Node3D):
	if not is_active:
		return
	# Check if the body is an enemy (you'll need a way to identify enemies)
	# For example, if enemies are in a group "enemies"
	if body.has_method("take_damage"): # or body is EnemyClass if you have one
		print("Mine triggered by: ", body.name)
		explode()
	# Optional: If player can trigger it
	# elif damage_player and body.is_in_group("player"):
	# print("Mine triggered by player!")
	# explode()

func explode():
	if explosion_scene:
		var explosion_instance = explosion_scene.instantiate()
		get_parent().add_child(explosion_instance) # Add to same level as mine
		explosion_instance.global_transform.origin = global_transform.origin
	
	queue_free() # Destroy the mine