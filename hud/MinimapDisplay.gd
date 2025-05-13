# MinimapDisplay.gd
extends Control

# Store the entity data locally within this control
var minimap_entities = {}

const BACKGROUND_COLOR = Color(0.1, 0.1, 0.1, 0.7)
const PLAYER_COLOR = Color(0, 1, 0) # Green
const CRATE_COLOR = Color(1, 1, 0) # Yellow
const ENEMY_COLOR = Color(1, 0, 0) # Red
const DEFAULT_COLOR = Color.WHITE # White
const ENTITY_RADIUS = 3.0 # Adjust as needed
# Add a scale factor if your incoming coordinates are too large/small for the minimap area
const MAP_SCALE = 0.3 # Example: 10 world units = 1 pixel on minimap. Adjust!

# Keep track of the player's position to center the map (optional, but common)
var player_map_position = Vector2.ZERO

var wall_data: Array = GameConfig.wall_definitions

# Called when the node is ready
func _ready() -> void:
	# Ensure the control redraws when its size changes (e.g., due to window resizing)
	resized.connect(queue_redraw)


# --- Public methods to be called from HUD.gd ---
func update_entity(entity, entity_type, world_position_2d) -> void:
	# --- Coordinate Transformation ---
	# This is crucial. The incoming 'world_position_2d' needs to be converted
	# into coordinates relative to the MinimapDisplay's top-left corner.
	# A common approach is to center the minimap on the player.

	# 1. Calculate the map position (scaling the world position)
	var map_position = world_position_2d * MAP_SCALE

	# 2. Store the raw map position
	minimap_entities[entity] = {
		"type": entity_type,
		"map_position": map_position
	}

	# 3. If this entity is the player, store their map position separately
	if entity_type == "player":
		player_map_position = map_position
	
	#print("MinimapDisplay Update: ", entity_type, " at map_pos ", map_position)
	queue_redraw() # Request a redraw because data changed

func remove_entity(entity):
	if minimap_entities.has(entity):
		minimap_entities.erase(entity)
		queue_redraw() # Request a redraw because data changed
		#print("MinimapDisplay Update: Removed entity ", entity)

# --- Drawing Logic ---
func _draw() -> void:
	# Get the size of this control
	var minimap_rect = Rect2(Vector2.ZERO, size)

	# Draw the background
	draw_rect(minimap_rect, BACKGROUND_COLOR)

	# Draw the walls
	for wall in wall_data:
		var wall_pos = Vector2(wall.x * MAP_SCALE, wall.y * MAP_SCALE)
		var wall_size = Vector2(wall.width * MAP_SCALE, wall.height * MAP_SCALE)
		draw_rect(Rect2(wall_pos, wall_size), Color(1.0, 1.0, 1.0)) # Black for walls

	# Calculate the center of the minimap control
	var minimap_center = size / 2.0

	# --- Draw Entities ---
	for entity in minimap_entities:
		var data = minimap_entities[entity]
		var entity_map_pos = data.map_position
		var entity_type = data.type

		# Calculate the entity's position relative to the player on the map
		var relative_pos = entity_map_pos - player_map_position

		# Translate this relative position so the player apppears at the minimap center
		var draw_pos = minimap_center + relative_pos

		# Check if the draw position is within the minimap bounds before drawing
		if minimap_rect.has_point(draw_pos):
			var color = DEFAULT_COLOR
			match entity_type:
				"player":
					color = PLAYER_COLOR
				"crate":
					color = CRATE_COLOR
				"enemy":
					color = ENEMY_COLOR
			
			draw_circle(draw_pos, ENTITY_RADIUS, color)
