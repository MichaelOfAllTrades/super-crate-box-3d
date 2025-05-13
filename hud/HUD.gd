# HUD.gd
extends Control

# Export variables for easy editing in the Inspector
@export var crosshair_text = "+"
@export var crosshair_font_size = 48
@export var crosshair_color = Color(1, 0, 0) # Red color

@export var effect_texture: Texture = null
@export var effet_duration: float = 0.15

var crates_count = 0
# Get references to the nodes you need to update
# @onready var health_label = $MarginContainer/VBoxContainer/HealthLabel
# @onready var health_bar = $MarginContainer/VBoxContainer/HealthBar
# @onready var ammo_label = $MarginContainer/VBoxContainer/AmmoLabel
@onready var crates_count_label = $MarginContainer/CenterContainer/CratesCountLabel
# Add @onready vars for other elements (crosshair, weapon name, etc.)

# var minimap_entities = {}

@onready var minimap_display = $MinimapDisplay

const BACKGROUND_COLOR = Color(0.1, 0.1, 0.1, 0.7)

# game over
@onready var game_over_label = $GameOverLabel # reference to the Game Over label

func _ready():
	# Initialize the label text
	crates_count_label.text = "Crates " + str(crates_count)

	# Connect to the Autoload signal
	# GameEvents is globally accessible because it's an Autoload
	GameEvents.connect("crate_collected", Callable(self, "on_crate_collected"))

	MinimapEvents.connect("entity_position_updated", Callable(self, "_on_minimap_entity_position_updated"))
	MinimapEvents.connect("entity_removed", Callable(self, "_on_minimap_entity_removed"))

	# game over
	game_over_label.hide()
	GameEvents.connect("game_over", Callable(self, "_on_game_over"))
	GameEvents.connect("game_restarted", Callable(self, "_on_game_restarted"))

# game over
func _on_game_over():
	game_over_label.show()
func _on_game_restarted():
	game_over_label.hide()

# Function to handle the signal emitted by the crate
func on_crate_collected(_crate_node): # _crate_node parameter is ignored if we only need the count
	# Increment the count
	crates_count += 1
	# Update the label text
	crates_count_label.text = "Crates " + str(crates_count)
	print("HUD: Crate count updated to ", crates_count)


# MINIMAP
func _on_minimap_entity_position_updated(entity, entity_type, position_2d):
	# Store or update the entity's data
	# minimap_entities[entity] = { "type": entity_type, "position": position_2d }
	# print("Minimap Update: ", entity_type, " (", entity_type, ") at ", position_2d)
	if minimap_display:
		# minimap_display.queue_redraw()
		minimap_display.update_entity(entity, entity_type, position_2d)
	queue_redraw()

func _on_minimap_entity_removed(entity):
	# if minimap_entities.has(entity):
	# 	minimap_entities.erase(entity)
		# print("Minimap Update: Removed entity ", entity)
		if minimap_display:
			# minimap_display.queue_redraw()
			minimap_display.remove_entity(entity)
		queue_redraw()

# func _draw():
# 	print("_draw content: ", minimap_entities)
# 	if not minimap_display:
# 		var minimap_local_rect = Rect2(size.x - 210, size.y - 210, 200, 200) # Example bottom-right
# 		var minimap_draw_pos = minimap_display.position
# 		# draw_rect(minimap_rect, Color(0, 0, 0, 0.5))

# 		draw_rect(minimap_local_rect, BACKGROUND_COLOR)

# 		# draw rect at 0,0
# 		draw_rect(Rect2(0, 0, 200, 200), BACKGROUND_COLOR)


# 		for entity in minimap_entities:
# 			var data = minimap_entities[entity]
# 			var pos = data.position
# 			var type = data.type

# 			if minimap_local_rect.has_point(pos):
# 				var color = Color.WHITE
# 				if type == "player":
# 					color = Color(0, 1, 0) # Green for player
# 				elif type == "crate":
# 					color = Color(1, 1, 0) # Yellow for crate
# 				elif type == "enemy":
# 					color = Color(1, 0, 0) # Red for enemy
# 				draw_circle(pos, 3, color)