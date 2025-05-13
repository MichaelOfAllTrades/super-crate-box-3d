extends Node3D

#@export var SCALE_FACTOR: float = 1.0
#@export var CENTER_CONTENT: bool = true
#const CREATE_PHYSICS: bool = true
#
#const ORIGINAL_WIDTH: float = 960.0
#const ORIGINAL_HEIGHT: float = 640.0
#
##@export var wall_prefab : PackedScene
#var wall_data_list : Array = []
#var walls : Array = []
#
@export var wall_scene: PackedScene
#
#var height = 640
#
### Parameters for level generation
#@export var platform_thickness: float = 300.0
#@export var front_back_wall_thickness: float = 10.0
#@export var front_wall_z: float = -100.0
#@export var back_wall_z: float = 100.0
#@export var map_overall_width: float = 960.0 # Total X-extent
#@export var map_overall_height: float = 640.0 # Total Y-extent

# Define your wall/platform layout data here
# Using an array of dictionaries is convenient
var wall_definitions = [
	# Name is just for reference/debugging
	{"name": "left_most_wall", "x": 0, "y": 0, "width": 40, "height": 560},
	{"name": "left_roof", "x": 40, "y": 0, "width": 400, "height": 40},
	{"name": "left_base_bottom", "x": 0, "y": 600, "width": 440, "height": 40},
	{"name": "left_base_top", "x": 0, "y": 560, "width": 240, "height": 40},
	{"name": "left_middle", "x": 0, "y": 293, "width": 240, "height": 40},

	{"name": "upper_platform", "x": 240, "y": 189, "width": 478, "height": 40},
	{"name": "lower_platform", "x": 240, "y": 440, "width": 480, "height": 40},

	{"name": "right_most_wall", "x": 920, "y": 0, "width": 40, "height": 560},
	{"name": "right_roof", "x": 520, "y": 0, "width": 400, "height": 40},
	{"name": "right_base_bottom", "x": 520, "y": 600, "width": 440, "height": 40},
	{"name": "right_base_top", "x": 720, "y": 560, "width": 240, "height": 40},
	{"name": "right_middle", "x": 720, "y": 293, "width": 240, "height": 40},

	# {"name": "back", "x": 0, "y": 0, "width": 960, "height": 640},
]

@export var crate_scene: PackedScene
@export var crate_spawn_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	print("Generating map")
	#generate_level_geometry()
	generate_level_geometry2()
	generate_back_wall()
	# generate_front_wall()

	var godot_spawn_areas = GameConfig.get_spawn_areas_godot_coords()
	# print("spawn areas ", godot_spawn_areas)
	# visualize_areas(godot_spawn_areas, self)
	var _random_spawn_point = GameConfig.get_random_point_in_areas(godot_spawn_areas)
	# generate_crate_spawn_positions()
	# print("scale factor ", GameConfig.SCALE_FACTOR)
	
	var x = GameConfig.target_ratio

# func generate_crate_spawn_positions():
# 	for spawn in GameConfig.spawn_pos:
# 		var corner1: Vector3 = spawn[0]
# 		var corner2: Vector3 = spawn[1]

# 		var box_size = Vector3(
# 			abs(corner2.x - corner1.x),
# 			abs(corner2.y - corner1.y),
# 			abs(corner2.z - corner1.z)
# 		)

# 		# Calculate the center position of the box
# 		# The center is simply the midpoint between the two opposite corners
# 		var box_center_position = (corner1 + corner2) / 2.0

# 		var area_mesh_instance = MeshInstance3D.new()

# 		var box_mesh = BoxMesh.new()
# 		box_mesh.size = box_size
# 		area_mesh_instance.mesh = box_mesh
# 		area_mesh_instance.position = box_center_position
# 		add_child(area_mesh_instance)

## Visualizes a list of 3D rectangular areas using blue BoxMesh instances.
## This function expects the areas_list to contain Vector3 points that are
## ALREADY IN THE FINAL GODOT 3D WORLD COORDINATE SYSTEM.
##
## Args:
##   areas_list_godot_coords: An Array where each element is an Array like [Vector3(), Vector3()]
##                            where Vector3s are in Godot world space.
##   visual_parent: The Node3D parent to add the visual meshes to.
func visualize_areas(areas_list_godot_coords: Array, visual_parent: Node3D) -> void:
	# Ensure we have a parent node to add the visuals to
	if visual_parent == null:
		push_error("visual_parent Node3D is not assigned. Cannot visualize areas.")
		return

	# Iterate through each area definition (which are already in Godot coords)
	for area_godot in areas_list_godot_coords:
		# Basic check (less strict now, assuming input from GameConfig is reliable)
		if not (area_godot is Array and area_godot.size() == 2 and area_godot[0] is Vector3 and area_godot[1] is Vector3):
			push_warning("Skipping invalid converted area format: ", area_godot)
			continue
		print("Visualizing area: ", area_godot)

		var corner1_godot: Vector3 = area_godot[0]
		var corner2_godot: Vector3 = area_godot[1]

		# Calculate the size of the box directly from the Godot corner points
		var box_size = (corner2_godot - corner1_godot).abs() # Use abs() to get positive size

		# Calculate the center position of the box
		var box_center_position = (corner1_godot + corner2_godot) / 2.0

		var crate_spawn_instance = crate_spawn_scene.instantiate()

		crate_spawn_instance.position = box_center_position
		if crate_spawn_instance.has_method("set_size"):
			crate_spawn_instance.set_size(box_size)
		# Add the mesh instance as a child of the specified visual_parent node
		visual_parent.add_child(crate_spawn_instance)

	print("Visualization complete for ", areas_list_godot_coords.size(), " converted areas.")


## Gets a random point from within a collection of 3D rectangular areas.
## This function expects the areas_list to contain Vector3 points that are
## ALREADY IN THE FINAL GODOT 3D WORLD COORDINATE SYSTEM.
##
## Args:
##   areas_list_godot_coords: An Array where each element is an Array like [Vector3(), Vector3()]
##                            where Vector3s are in Godot world space.
##
## Returns:
##   A random Vector3 point within one of the areas, or null if the areas_list is empty or invalid.





func generate_level_geometry():
	# --- Generate Standard Walls/Platforms ---
	for wall_data in wall_definitions:
		var wall_instance = wall_scene.instantiate()
		
		# Check if the instance has the expected properties/methods before setting them
		if wall_instance.has_method("set_thickness") and wall_instance.has_method("set_original_width") and wall_instance.has_method("set_original_height"):
			# Set properties using the setter functions (or directly if no setters exist)
			wall_instance.set_thickness(GameConfig.platform_thickness)
			wall_instance.set_original_width(wall_data["width"])
			wall_instance.set_original_height(wall_data["height"])
			# Calculate position (center of the wall in 3D)
			# Assuming your Y=0 is the top in 2D, and you want Y=0 to be bottom in 3D?
			# Let's stick to the previous assumption: Python Y maps directly to Godot Y (Y increases upwards)
			# Adjust the Y calculation if needed (e.g., map_overall_height - wall_data.y - wall_data.height / 2.0)
			var pos_x = wall_data["x"] + wall_data["width"] / 2.0
			var pos_y = wall_data["y"] + (GameConfig.target_height - wall_data["height"]) / 2.0
			var pos_z = 0 # Center the standard walls/platforms on the Z=0 plane
			#print(wall_data['name'])
			#print("x ", pos_x)
			#print("y ", pos_y)
			#print("height - y ", (GameConfig.target_height - wall_data["height"]))
			#print("z ", pos_z)
			wall_instance.position = Vector3(pos_x, pos_y, pos_z)
			
			# Set name for easier debugging in Remote scene tree
			wall_instance.name = wall_data["name"]
			
			# Add the wall to the level scene
			add_child(wall_instance)
		else:
			#printerr("Wall instance from wall_scene does not have expected properties/methods!")
			wall_instance.queue_free() # Clean up unusable instance

func generate_level_geometry2():
	# Determine the target dimensions in world units based on the *longest* original dimension
	# and the scale factor. This maintains aspect ratio.

	# Decide target size based on a desired width or height in world units
	# Here, we base it on the WORLD_SCALE_FACTOR representing the width
	#target_width = ORIGINAL_WIDTH * SCALE_FACTOR
	#print("target width ", target_width)
	#target_height = ORIGINAL_HEIGHT * (SCALE_FACTOR / aspect_ratio)
	#print("target height ", target_height)
	# Alternatively, base it on height:
	# target_height = WORLD_SCALE_FACTOR
	# target_width = WORLD_SCALE_FACTOR * aspect_ratio

	# Calculate offset to center the content within the target area (relative to this Node3D's origin)
	var offset_x: float = 0.0
	var offset_y: float = 0.0 # In 3D, this is the Y offset (up/down)
	if GameConfig.CENTER_CONTENT:
		# Centering means the middle of the content area is at the Node3D's origin (0,0,0)
		# So, the top-left corner calculation needs adjustment.
		# We'll calculate relative positions first, then adjust the final position.
		pass # Offsetting is handled slightly differently below due to mesh origins

	# --- Clear previous walls if regenerating ---
	# (Optional, same logic as 2D if needed)

	# --- Generate new walls ---
	for wall_data in wall_definitions:
		#print("name ", wall_data["name"])
		# 1. Calculate percentages relative to original dimensions (same as 2D)
		var percent_x: float = wall_data.x / GameConfig.ORIGINAL_WIDTH
		#print("percent x ", percent_x)
		var percent_y: float = wall_data.y / GameConfig.ORIGINAL_HEIGHT
		#print("percent y ", percent_y)
		var percent_width: float = wall_data.width / GameConfig.ORIGINAL_WIDTH
		#print("percent w ", percent_width)
		var percent_height: float = wall_data.height / GameConfig.ORIGINAL_HEIGHT
		#print("percent h ", percent_height)

		# 2. Calculate 3D dimensions (Size) based on percentages and target world size
		var godot_size_x: float = percent_width * GameConfig.target_width
		#print("godot size x ", godot_size_x)
		var godot_size_y: float = percent_height * GameConfig.target_height
		#print("godot size y ", godot_size_y)
		var godot_size_z: float = GameConfig.platform_thickness # Use the constant depth
		#print("godot size z ", godot_size_z)
		var godot_size = Vector3(godot_size_x, godot_size_y, godot_size_z)

		# 3. Calculate 3D position
		# BoxMesh/BoxShape origin is in the CENTER of the box.
		# We need to calculate the center position in world space.

		# Calculate the center X position relative to the target area's left edge
		var center_x_relative = (percent_x + percent_width / 2.0) * GameConfig.target_width
		#print("center x relative ", center_x_relative)
		#print("")
		# Calculate the center Y position relative to the target area's *bottom* edge
		# because 3D Y is UP, but original Y was DOWN from the top.
		# (1.0 - percent_y) gives the percentage from the *bottom* edge to the *top* of the original rect.
		# (1.0 - percent_y - percent_height / 2.0) gives the percentage from the *bottom* edge to the *center* of the original rect.
		var center_y_relative = (1.0 - percent_y - percent_height / 2.0) * GameConfig.target_height

		# Adjust for centering the whole layout
		var final_center_x = center_x_relative
		var final_center_y = center_y_relative
		if GameConfig.CENTER_CONTENT:
			final_center_x -= GameConfig.target_width / 2.0
			final_center_y -= GameConfig.target_height / 2.0

		# Final 3D position (Z is 0 relative to this parent Node3D)
		var godot_position = Vector3(final_center_x, final_center_y, 0.0)

		# 4. Create the Godot Nodes

		# Choose parent node based on whether we create physics
		var parent_node = self # Default parent is this script's node
		var mesh_relative_position = godot_position # Default if mesh is direct child

		if GameConfig.CREATE_PHYSICS:
			# Create StaticBody3D
			var static_body = StaticBody3D.new()
			static_body.name = wall_data.name + "_CollisionBody"
			static_body.position = godot_position # Position the body

			# Create CollisionShape3D
			var collision_shape = CollisionShape3D.new()
			var box_shape = BoxShape3D.new()
			box_shape.size = godot_size # Use calculated 3D size
			collision_shape.shape = box_shape
			# CollisionShape position is relative to StaticBody, should be zero
			# because BoxShape center matches StaticBody origin.
			collision_shape.position = Vector3.ZERO

			static_body.add_child(collision_shape)
			self.add_child(static_body)

			# If physics exists, make it the parent for the visual mesh
			parent_node = static_body
			# Mesh position is now relative to the StaticBody, so it should be zero
			mesh_relative_position = Vector3.ZERO

		# Create MeshInstance3D (Visual)
		var wall_mesh_instance = MeshInstance3D.new()
		wall_mesh_instance.name = wall_data.name
		
		# Create the BoxMesh geometry
		var box_mesh = BoxMesh.new()
		box_mesh.size = godot_size # Use calculated 3D size
		wall_mesh_instance.mesh = box_mesh

		# Apply material if configured
		#if CREATE_MATERIAL and _black_material:
			## Godot 4+: Set material override for simplicity
			#wall_mesh_instance.material_override = _black_material
				## Godot 3.x: Set surface material
				## wall_mesh_instance.set_surface_material(0, _black_material)

		# Set position (relative to parent_node)
		wall_mesh_instance.position = mesh_relative_position

		# Add the mesh to the appropriate parent
		parent_node.add_child(wall_mesh_instance)
	
func generate_back_wall():
	#print("GENERATE_BACK_WALL")
	var back_wall_thickness = GameConfig.front_back_wall_thickness # Assuming you have a config value for this
	# Adjust Z position based on center of the main platforms and back wall thickness
	# Assuming platforms are centered around Z=0
	var back_wall_pos_z = (0.0 - (GameConfig.platform_thickness / 2.0)) - (back_wall_thickness / 2.0)
	
	# Calculate the center X/Y for the back wall.
	# It should cover the whole scaled original area.
	var center_x = 0.0 # If CENTER_CONTENT is true, the center of the whole area is at 0,0
	var center_y = 0.0
	
	# If not centering, the top-left of the scaled area would be at 0,0.
	# The center would be at half the scaled width/height.
	if !GameConfig.CENTER_CONTENT:
		center_x = (GameConfig.ORIGINAL_WIDTH * GameConfig.SCALE_FACTOR) / 2.0
		# Y is trickier because original was top-down, Godot is bottom-up.
		# The bottom of the scaled area is at 0 if not centered (assuming Y=0 is bottom).
		# The top is at GameConfig.target_height.
		# The center is at GameConfig.target_height / 2.0.
		center_y = GameConfig.target_height / 2.0 # Use target_height calculated based on scaled width

	var back_wall_pos = Vector3(center_x, center_y, back_wall_pos_z)

	var parent_node = self
	var mesh_relative_pos = Vector3.ZERO # Mesh will be relative to parent (StaticBody or self)

	# The size should match the target dimensions calculated in generate_level_geometry2
	# (assuming back wall covers the whole scaled map area)
	var back_wall_size = Vector3(GameConfig.target_width, GameConfig.target_height, back_wall_thickness)
	
	if GameConfig.CREATE_PHYSICS:
		var static_body = StaticBody3D.new()
		static_body.name = "back_wall_CollisionBody"
		static_body.position = back_wall_pos # Position the StaticBody

		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = back_wall_size
		collision_shape.shape = box_shape
		# CollisionShape position is relative to StaticBody, should be zero
		collision_shape.position = Vector3.ZERO

		static_body.add_child(collision_shape)
		self.add_child(static_body)

		# If physics exists, make it the parent for the visual mesh
		parent_node = static_body
		# mesh_relative_pos is already Vector3.ZERO for relative placement

	# Create MeshInstance3D (Visual)
	var back_wall_mesh_instance = MeshInstance3D.new()
	back_wall_mesh_instance.name = "back_wall_mesh"

	# Create the BoxMesh geometry resource
	var box_mesh = BoxMesh.new()
	box_mesh.size = back_wall_size

	# *** FIX: Assign the BoxMesh resource to the mesh property of the MeshInstance3D node ***
	back_wall_mesh_instance.mesh = box_mesh

	# Apply material if configured (Optional, copy from generate_level_geometry2 if needed)
	# if CREATE_MATERIAL and _black_material:
	#     back_wall_mesh_instance.material_override = _black_material # Godot 4+
	#     # back_wall_mesh_instance.set_surface_material(0, _black_material) # Godot 3.x

	# Set position (relative to parent_node - which is StaticBody or self)
	# This should be Vector3.ZERO if parent_node is the StaticBody at the wall's position
	# or if parent_node is self and the mesh is placed directly.
	back_wall_mesh_instance.position = mesh_relative_pos # This is already Vector3.ZERO as set above

	# Add the mesh to the appropriate parent
	parent_node.add_child(back_wall_mesh_instance)

func generate_front_wall():
	var front_wall_thickness = GameConfig.front_back_wall_thickness
	var front_wall_pos_z = (0.0 + (GameConfig.platform_thickness / 2.0)) + (front_wall_thickness / 2.0)

	var center_x = 0.0
	var center_y = 0.0

	if !GameConfig.CENTER_CONTENT:
		center_x = (GameConfig.ORIGINAL_WIDTH * GameConfig.SCALE_FACTOR) / 2.0
		center_y = GameConfig.target_height / 2.0

	var front_wall_pos = Vector3(center_x, center_y, front_wall_pos_z)

	var parent_node = self
	var mesh_relative_pos = Vector3.ZERO

	var front_wall_size = Vector3(GameConfig.target_width, GameConfig.target_height, front_wall_thickness)

	if GameConfig.CREATE_PHYSICS:
		var static_body = StaticBody3D.new()
		static_body.name = "front_wall_CollisionBody"
		static_body.position = front_wall_pos

		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = front_wall_size
		collision_shape.shape = box_shape
		collision_shape.position = Vector3.ZERO

		static_body.add_child(collision_shape)
		self.add_child(static_body)

		parent_node = static_body
		mesh_relative_pos = Vector3.ZERO

	var front_wall_mesh_instance = MeshInstance3D.new()
	front_wall_mesh_instance.name = "front_wall_mesh"

	var box_mesh = BoxMesh.new()
	box_mesh.size = front_wall_size

	front_wall_mesh_instance.mesh = box_mesh

	# if CREATE_MATERIAL and _black_material:
	#     front_wall_mesh_instance.material_override = _black_material

	front_wall_mesh_instance.position = mesh_relative_pos

	parent_node.add_child(front_wall_mesh_instance)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#func get_spawn_parameters() -> Dictionary:
	#var spawn_x = 0.0
	##print("inside get_spawn_parameters ", GameConfig.ORIGINAL_HEIGHT, " ", GameConfig.SCALE_FACTOR)
	#var spawn_y = (GameConfig.ORIGINAL_HEIGHT * GameConfig.SCALE_FACTOR) / 2
	#var spawn_z = 0.0
	#
	#var spawn_pos = Vector3(spawn_x, spawn_y, spawn_z)
	#
	#return {
		#"spawn_pos": spawn_pos
	#}
