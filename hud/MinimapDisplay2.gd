# MinimapDisplay.gd
extends Control

# Store the entity data locally - store the *world* position
var minimap_entities = {} # Format: { entity_id: {"type": "player", "world_pos": Vector3} }

# --- Colors ---
const BACKGROUND_COLOR = Color(0.1, 0.1, 0.1, 0.7)
const WALL_COLOR = Color(0.8, 0.8, 0.8, 0.9) # Light gray for walls
const PLAYER_COLOR = Color(1, 0.5, 0) # Orange
# const PLAYER_COLOR = Color(0, 1, 0) # Orange

# make crate brown
const CRATE_COLOR = Color(0.5, 0.25, 0) # Brown
# const CRATE_COLOR = Color(1, 1, 0) # Yellow

# make slow enemy green
const SLOW_ENEMY_COLOR = Color(0, 1, 0) # Green
# const ENEMY_COLOR = Color(1, 0, 0) # Red

# make fast enemy red
const FAST_ENEMY_COLOR = Color(1, 0, 0) # Red
const DEFAULT_COLOR = Color.WHITE # White
const ENTITY_RADIUS = 3.0 # Adjust draw size of entities

# We'll calculate scale factors based on the control's size
var scale_x : float = 1.0
var scale_y : float = 1.0

# Called when the node is ready
func _ready():
	# Recalculate scale factors when the control is ready and when resized
	_update_scale_factors()
	resized.connect(_on_resized)

	# Initial draw request
	queue_redraw()


func _on_resized():
	# Recalculate scale when the minimap control size changes
	_update_scale_factors()
	queue_redraw()


func _update_scale_factors():
	# Ensure GameConfig and its dimensions are available and valid
	if not GameConfig or GameConfig.ORIGINAL_WIDTH <= 0 or GameConfig.ORIGINAL_HEIGHT <= 0:
		printerr("MinimapDisplay: GameConfig not available or ORIGINAL dimensions invalid.")
		scale_x = 1.0
		scale_y = 1.0
		return

	if size.x <= 0 or size.y <= 0:
		# Size might be zero during initialization, handle gracefully
		# print("MinimapDisplay: Control size is zero, skipping scale update for now.")
		return

	# Calculate how to scale the original pixel coordinates to fit this control
	scale_x = size.x / GameConfig.ORIGINAL_WIDTH
	scale_y = size.y / GameConfig.ORIGINAL_HEIGHT
	# print("MinimapDisplay: Updated scale factors: ", scale_x, ", ", scale_y)


# --- Public methods to be called from HUD.gd ---

func update_entity(entity, entity_type, world_position_3d):
	# Store the 3D world position directly
	minimap_entities[entity] = { "type": entity_type, "world_pos": world_position_3d }
	# print("MinimapDisplay Update Entity: ", entity_type, " at world_pos ", world_position_3d)
	queue_redraw() # Request a redraw because data changed

func remove_entity(entity):
	if minimap_entities.has(entity):
		minimap_entities.erase(entity)
		# print("MinimapDisplay Remove Entity: ", entity)
		queue_redraw() # Request a redraw


# --- Coordinate Transformation Helpers ---

# Converts a Godot 3D world position back into the approximate original 2D pixel coordinates
func world_to_original(world_pos: Vector2) -> Vector2:
	# Ensure GameConfig and target dimensions are available
	if not GameConfig or GameConfig.target_width <= 0 or GameConfig.target_height <= 0:
		printerr("MinimapDisplay: GameConfig not available or target dimensions invalid for world_to_original.")
		return Vector2.ZERO # Return a default value

	var gx = world_pos.x
	var gy = world_pos.y

	# Reverse the centering offset applied during 3D generation (if any)
	var center_x_relative = gx
	var center_y_relative = gy
	if GameConfig.CENTER_CONTENT:
		center_x_relative += GameConfig.target_width / 2.0
		center_y_relative += GameConfig.target_height / 2.0

	# Reverse the scaling from percentages to target dimensions
	# Treat entity as a point (percent_width/height = 0)
	# center_x_relative = percent_x * GameConfig.target_width
	var percent_x = center_x_relative / GameConfig.target_width

	# center_y_relative = (1.0 - percent_y) * GameConfig.target_height (treating percent_height as 0)
	# (1.0 - percent_y) = center_y_relative / GameConfig.target_height
	var percent_y = 1.0 - (center_y_relative / GameConfig.target_height)

	# Convert percentages back to original pixel coordinates
	var original_x = percent_x * GameConfig.ORIGINAL_WIDTH
	var original_y = percent_y * GameConfig.ORIGINAL_HEIGHT

	return Vector2(original_x, original_y)


# Converts original 2D pixel coordinates to the minimap's local coordinates
func original_to_minimap(original_pos: Vector2) -> Vector2:
	# Apply the calculated scale factors
	return Vector2(original_pos.x * scale_x, original_pos.y * scale_y)

# Converts an original wall definition rect into a minimap Rect2
func original_wall_to_minimap_rect(wall_data: Dictionary) -> Rect2:
	var minimap_x = wall_data.x * scale_x
	var minimap_y = wall_data.y * scale_y
	var minimap_width = wall_data.width * scale_x
	var minimap_height = wall_data.height * scale_y
	return Rect2(minimap_x, minimap_y, minimap_width, minimap_height)


# --- Drawing Logic ---

func _draw():
	# print("MinimapDisplay _draw call. Entities: ", minimap_entities.size())
	# Get the size of this control
	var minimap_rect = Rect2(Vector2.ZERO, size)

	# 1. Draw the background
	draw_rect(minimap_rect, BACKGROUND_COLOR)

	# Check if GameConfig is available before drawing things based on it
	if not GameConfig:
		printerr("MinimapDisplay: GameConfig not available in _draw.")
		return # Cannot draw walls or entities without GameConfig

	# 2. Draw the static walls
	for wall_data in GameConfig.wall_definitions:
		var wall_rect_minimap = original_wall_to_minimap_rect(wall_data)
		draw_rect(wall_rect_minimap, WALL_COLOR)


	# 3. Draw the dynamic entities
	for entity_id in minimap_entities:
		var data = minimap_entities[entity_id]
		var world_pos = data.world_pos
		var entity_type = data.type

		# Convert world 3D -> original 2D -> minimap 2D
		var original_pos = world_to_original(world_pos)
		var draw_pos = original_to_minimap(original_pos)

		# Check if the draw position is roughly within the minimap bounds before drawing
		# (Add a small margin to catch entities slightly outside)
		if minimap_rect.grow(ENTITY_RADIUS * 2).has_point(draw_pos):
			var color: Color = DEFAULT_COLOR
			var width: float = 0.0
			var height: float = 0.0
			# print("entity type: ", entity_type)
			match entity_type:
				"player":
					color = PLAYER_COLOR
					width = 21 * scale_x
					height = 21 * scale_y
				"crate":
					color = CRATE_COLOR
					width = GameConfig.crate_width * scale_x
					height = GameConfig.crate_height * scale_y
				"small enemy true":
					color = FAST_ENEMY_COLOR
					width = GameConfig.small_enemy_width * scale_x
					height = GameConfig.small_enemy_height * scale_y
				"small enemy false":
					color = SLOW_ENEMY_COLOR
					width = GameConfig.small_enemy_width * scale_x
					height = GameConfig.small_enemy_height * scale_y
				"big enemy true":
					color = FAST_ENEMY_COLOR
					width = GameConfig.big_enemy_width * scale_x
					height = GameConfig.big_enemy_height * scale_y
				"big enemy false":
					color = SLOW_ENEMY_COLOR
					width = GameConfig.big_enemy_width * scale_x
					height = GameConfig.big_enemy_height * scale_y
			
			# Calculate the top-left corner for the rectangle to be centered
			var rect_pos = draw_pos - Vector2(width / 2.0, height / 2.0)
			var rect_size = Vector2(width, height)
			var entity_rect = Rect2(rect_pos, rect_size)
			
			# Draw the entity as a rectangle centered on its position
			draw_rect(entity_rect, color)
