# wall.gd
extends StaticBody3D

# Export variables to make them editable in the Inspector
## The thickness (depth) of the wall along the Z-axis
@export var thickness: float = 10.0: set = set_thickness
## The dimensions from the 2D game (used for initial setup)
@export var original_width: float = 40.0
@export var original_height: float = 40.0

# References to child nodes (assigned in _ready)
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready():
	add_to_group("wall")
	# Initial setup based on exported variables when the scene loads
	_update_dimensions()

# Function to update mesh and collision shape based on properties
func _update_dimensions():
	if mesh_instance and mesh_instance.mesh is BoxMesh and collision_shape and collision_shape.shape is BoxShape3D:
		
		# BoxMesh size is full extent (width, height, depth)
		# BoxShape3D size is also full extent
		var new_size = Vector3(original_width, original_height, thickness)
		
		# Update Mesh Size
		mesh_instance.mesh.size = new_size
		
		# Update Collision Shape Size
		collision_shape.shape.size = new_size
		
		# Note: Position is set when instancing the wall in the main level scene.
		# The origin (0,0,0) of the Wall scene is its center.

# Setter function for thickness - updates dimensions when changed in Inspector
func set_thickness(value: float):
	thickness = value
	if is_node_ready(): # Only update if the node is ready
		_update_dimensions()

# Optional: Setter functions if you want to adjust width/height later
func set_original_width(value: float):
	original_width = value
	if is_node_ready():
		_update_dimensions()

func set_original_height(value: float):
	original_height = value
	if is_node_ready():
		_update_dimensions()
