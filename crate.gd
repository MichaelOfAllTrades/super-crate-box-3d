# crate.gd
extends CharacterBody3D

# Export variables to make them editable in the Inspector
## The thickness (depth) of the wall along the Z-axis
@export var thickness: float = 10.0: set = set_thickness
## The dimensions from the 2D game (used for initial setup)
var w: float = GameConfig.crate_width
var h: float = GameConfig.crate_height

# References to child nodes (assigned in _ready)
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

@export var gravity_acceleration: float = 9.8
@export var terminal_velocity: float = 20.02
@export var y_speed: float = 0.0

var godot_spawn_areas = GameConfig.godot_spawn_areas
signal minimap_update(entity_id, entity_type, position_2d)
var MY_TYPE = GameConfig.EntityType.CRATE

func _ready():
	# Initial setup based on exported variables when the scene loads
	_update_dimensions()

	var random_spawn_point = GameConfig.get_random_point_in_areas(godot_spawn_areas)

	set_pos(random_spawn_point)

# Function to update mesh and collision shape based on properties
func _update_dimensions():
	if mesh_instance and mesh_instance.mesh is BoxMesh and collision_shape and collision_shape.shape is BoxShape3D:
		
		# BoxMesh size is full extent (width, height, depth)
		# BoxShape3D size is also full extent
		var new_size = Vector3(w, h, w)
		
		# Update Mesh Size
		mesh_instance.mesh.size = new_size
		
		# Update Collision Shape Size
		collision_shape.shape.size = new_size
		
		# Note: Position is set when instancing the wall in the main level scene.
		# The origin (0,0,0) of the Wall scene is its center.
		
		
func _physics_process(delta):
	var movement = Vector3(0, y_speed, 0)

	var collision = move_and_collide(movement * delta)

	if collision:
		var collision_normal = collision.get_collider()

		if collision_normal.y > 0.7:
			y_speed = 0
		else:
			y_speed += gravity_acceleration * delta
	
	var current_pos_3d = global_transform.origin
	var current_pos_2d = Vector2(current_pos_3d.x, current_pos_3d.z)
	emit_signal("minimap_update", self.get_instance_id(), MY_TYPE, current_pos_2d)

# Setter function for thickness - updates dimensions when changed in Inspector
func set_thickness(value: float):
	thickness = value
	if is_node_ready(): # Only update if the node is ready
		_update_dimensions()

func set_pos(vals: Vector3):
	self.transform.origin = vals

func handle_player_collision():
	var random_spawn_point = GameConfig.get_random_point_in_areas(godot_spawn_areas)

	set_pos(random_spawn_point)

# Optional: Setter functions if you want to adjust width/height later
#func set_original_width(value: float):
	#original_width = value
	#if is_node_ready():
		#_update_dimensions()
#
#func set_original_height(value: float):
	#original_height = value
	#if is_node_ready():
		#_update_dimensions()
