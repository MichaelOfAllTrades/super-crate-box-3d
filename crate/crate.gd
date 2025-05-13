# crate.gd
extends CharacterBody3D

# Export variables to make them editable in the Inspector
## The thickness (depth) of the wall along the Z-axis
@export var thickness: float = 10.0: set = set_thickness
## The dimensions from the 2D game (used for initial setup)
var w: float = GameConfig.crate_width / 2
var h: float = GameConfig.crate_height / 2

# References to child nodes (assigned in _ready)
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D


# @onready var emitting_node = get_node("Player/Player")

var gravity: float = 300.8
# var velocity: Vector3 = Vector3.ZERO
@onready var area_3d: Area3D = $Area3D
@onready var collision_shape_area: CollisionShape3D = $Area3D/CollisionShape3D # Reference area shape too

func _ready():
	add_to_group("crates") # add to group for easy access by 'c' later
	# Initial setup based on exported variables when the scene loads
	_update_dimensions()

	randomize()
	global_transform.origin = GameConfig.get_random_point_in_areas(GameConfig.get_spawn_areas_godot_coords())

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

		collision_shape_area.shape.size = new_size
		
		# Note: Position is set when instancing the wall in the main level scene.
		# The origin (0,0,0) of the Wall scene is its center.
		
func _physics_process(delta):
	# print("crate position: ", global_transform.origin)
	# Apply gravity if not on the floor
	if not is_on_floor():
			velocity.y -= gravity * delta
	else:
			# Stop downward velocity when on floor
			velocity.y = 0

	# Apply movement
	# Use move_and_slide() for CharacterBody3D gravity/collision
	# Godot 3.x syntax: move_and_slide(linear_velocity, floor_normal)
	move_and_slide()

	# MINIMAP
	var current_pos_3d = global_transform.origin
	var current_pos_2d = Vector2(current_pos_3d.x, current_pos_3d.y)
	MinimapEvents.emit_signal("entity_position_updated", self, "crate", current_pos_2d)

# Setter function for thickness - updates dimensions when changed in Inspector
func set_thickness(value: float):
	thickness = value
	if is_node_ready(): # Only update if the node is ready
		_update_dimensions()

# This method is called by the Player 'c' key OR Area3D signal
func teleport_and_collect():
	print("Crate teleport_and_collect called!")

	# Emit the signal *before* teleporting so HUD updates
	GameEvents.emit_signal("crate_collected", self)

	# Teleport the crate to a random position
	if GameConfig and GameConfig.has_method("get_random_point_in_areas"):
			global_transform.origin = GameConfig.get_random_point_in_areas(GameConfig.get_spawn_areas_godot_coords())
			# Reset velocity after teleporting to prevent carrying momentum
			velocity = Vector3.ZERO
			print("Crate new position after teleport: ", global_transform.origin)
	else:
			printerr("GameConfig or get_random_point_in_areas not available for teleport!")


# Area3D body_entered signal handler
# func _on_Area3D_body_entered(body):
# 	print("Area3D body entered: ", body.name)
# 	# Check if the colliding body is the Player (using the group)
# 	if body.is_in_group("player"): # Check the group you added the player to
# 			print("Player entered Crate Area3D")
# 			teleport_and_collect()


func _on_area_3d_body_entered(body:Node3D) -> void:
	print("Area3D body entered: ", body.name)
	# Check if the colliding body is the Player (using the group)
	if body.is_in_group("player"): # Check the group you added the player to
			print("Player entered Crate Area3D")
			teleport_and_collect()

func _exit_tree():
	MinimapEvents.emit_signal("entity_removed", self)