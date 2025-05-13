extends Node

@export var SCALE_FACTOR: float = 0.6
@export var CENTER_CONTENT: bool = true
@export var CREATE_PHYSICS: bool = true

const ORIGINAL_WIDTH: float = 960.0
const ORIGINAL_HEIGHT: float = 640.0

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
]

var walls_map = {
	"left_most_wall": {"x": 0, "y": 0, "width": 40, "height": 560},
	"left_roof": {"x": 40, "y": 0, "width": 400, "height": 40},
	"left_base_bottom": {"x": 0, "y": 600, "width": 440, "height": 40},
	"left_base_top": {"x": 0, "y": 560, "width": 240, "height": 40},
	"left_middle": {"x": 0, "y": 293, "width": 240, "height": 40},
	"upper_platform": {"x": 240, "y": 189, "width": 478, "height": 40},
	"lower_platform": {"x": 240, "y": 440, "width": 480, "height": 40},
	"right_most_wall": {"x": 920, "y": 0, "width": 40, "height": 560},
	"right_roof": {"x": 520, "y": 0, "width": 400, "height": 40},
	"right_base_bottom": {"x": 520, "y": 600, "width": 440, "height": 40},
	"right_base_top": {"x": 720, "y": 560, "width": 240, "height": 40},
	"right_middle": {"x": 720, "y": 293, "width": 240, "height": 40}
}

var walls_set = {
	"left_most_wall_CollisionBody": null,
	"left_roof_CollisionBody": null,
	"left_base_bottom_CollisionBody": null,
	"left_base_top_CollisionBody": null,
	"left_middle_CollisionBody": null,
	"upper_platform_CollisionBody": null,
	"lower_platform_CollisionBody": null,
	"right_most_wall_CollisionBody": null,
	"right_roof_CollisionBody": null,
	"right_base_bottom_CollisionBody": null,
	"right_base_top_CollisionBody": null,
	"right_middle_CollisionBody": null
}

const ORIGINAL_SMALL_ENEMY_WIDTH: float = 9.0
const ORIGINAL_SMALL_ENEMY_HEIGHT: float = 10.0
const ORIGINAL_BIG_ENEMY_WIDTH: float = 19.0
const ORIGINAL_BIG_ENEMY_HEIGHT: float = 20.0

var target_ratio: float = ORIGINAL_WIDTH / ORIGINAL_HEIGHT
var target_width: float = ORIGINAL_WIDTH * SCALE_FACTOR
var target_height: float = ORIGINAL_HEIGHT * SCALE_FACTOR

var dist_traveled_x: float = (ORIGINAL_WIDTH * SCALE_FACTOR) - (40 * 2 * SCALE_FACTOR) - (ORIGINAL_SMALL_ENEMY_WIDTH * 2 * SCALE_FACTOR)

@export var time_player_x: float = 1.8
var player_x_speed: float = dist_traveled_x / time_player_x

## Parameters for level generation
@export var platform_thickness: float = 200.0
@export var front_back_wall_thickness: float = 10.0
@export var front_wall_z: float = -100.0
@export var back_wall_z: float = 100.0

# enemies
@export var enemy_spawn_pos = Vector3(0.0, (ORIGINAL_HEIGHT * SCALE_FACTOR) - 50, 0.0)
@export var time_small_enemy_x_slow: float = 3.5
@export var time_small_enemy_x_fast: float = 1.8
@export var small_enemy_width: float = ORIGINAL_SMALL_ENEMY_WIDTH * SCALE_FACTOR * 2
@export var small_enemy_height: float = ORIGINAL_SMALL_ENEMY_HEIGHT * SCALE_FACTOR * 2
@export var small_enemy_speed_slow: float = dist_traveled_x / time_small_enemy_x_slow
@export var small_enemy_speed_fast: float = dist_traveled_x / time_small_enemy_x_fast
@export var small_enemy_gravity: float = 30.0
@export var big_enemy_width: float = ORIGINAL_BIG_ENEMY_WIDTH * SCALE_FACTOR * 2
@export var big_enemy_height: float = ORIGINAL_BIG_ENEMY_HEIGHT * SCALE_FACTOR * 2
@export var big_enemy_speed_slow: float = dist_traveled_x / time_small_enemy_x_slow
@export var big_enemy_speed_fast: float = dist_traveled_x / time_small_enemy_x_fast
@export var big_enemy_gravity: float = 70.0
# green
@export var slow_enemy_color: Color = Color(0.0, 1.0, 0.0, 1.0)
# red
@export var fast_enemy_color: Color = Color(1.0, 0.0, 0.0, 1.0)

@export var time_between_groups: float = 3.0
@export var time_between_small_group: float = 0.3

var enemy_spawn_pos_y : float = (target_height / 2) - 20

var num_enemies = 0


# crate
@export var crate_width: float = 32 * SCALE_FACTOR * 2
@export var crate_height: float = 31 * SCALE_FACTOR * 2
@export var crate_y_vel: float = 80.0

var spawn_pos = [
	[ # 0
		Vector3( # top left front
			walls_map["upper_platform"]['x'] + (crate_width / 2),
			walls_map["left_roof"]['y'] + walls_map["left_roof"]['height'] + (crate_height / 2),
			(platform_thickness / 2) - (crate_width / 2)
		),
		Vector3( # bottom right back
			walls_map["upper_platform"]['x'] + walls_map["upper_platform"]['width'] - (crate_width / 2),
			walls_map["upper_platform"]['y'] - (crate_height / 2),
			(-1 * platform_thickness / 2) + (crate_width / 2)
		),
	],
	[ # 1
		Vector3( # top left front
			walls_map["left_roof"]['x'] + (crate_width / 2),
			walls_map["left_roof"]['y'] + walls_map["left_roof"]['height'] + (crate_height / 2),
			(platform_thickness / 2) - (crate_width / 2)
		),
		Vector3( # bottom right back
			walls_map["left_middle"]['x'] + walls_map["left_middle"]['width'] - (crate_width / 2),
			walls_map["left_middle"]['y'] - (crate_height / 2),
			(-1 * platform_thickness / 2) + (crate_width / 2)
		)
	],
	[ # 2 WRONG RIGHT SIDE
		Vector3( # top left front
			walls_map["right_middle"]['x'] + (crate_width / 2),
			walls_map["right_roof"]['y'] + walls_map["right_roof"]['height'] + (crate_height / 2),
			(platform_thickness / 2) - (crate_width / 2)
		),
		Vector3( # bottom right back
			walls_map["right_middle"]['x'] + walls_map["right_middle"]['width'] - (crate_width / 1),
			walls_map["right_middle"]['y'] - (crate_width / 2),
			(-1 * platform_thickness / 2) + (crate_width / 2)
		)
	],
	[ # 3 (middle)
		Vector3( # top left front
			walls_map["lower_platform"]['x'] + (crate_width / 2),
			walls_map["upper_platform"]['y'] + walls_map["upper_platform"]['height'] + (crate_height / 2),
			(platform_thickness / 2) - (crate_width / 2)
		),
		Vector3( # bottom right back
			walls_map["lower_platform"]['x'] + walls_map["lower_platform"]['width'] - (crate_width / 2),
			walls_map["lower_platform"]['y'] - (crate_height / 2),
			(-1 * platform_thickness / 2) + (crate_width / 2)
		)
	],
	[ # 4 WRONG LEFT SIDE
		Vector3( # top left front
			walls_map["left_middle"]['x'] + (crate_width / 2),
			walls_map["left_middle"]['y'] + walls_map["left_middle"]['height'] + (crate_height / 2),
			(platform_thickness / 2) - (crate_width / 2)
		),
		Vector3( # bottom right back
			walls_map["left_base_top"]['x'] + walls_map["left_base_top"]['width'] - (crate_width / 2),
			walls_map["left_base_top"]['y'] - (crate_height / 2),
			(-1 * platform_thickness / 2) + (crate_width / 2)
		)
	],
	[ # 5
		Vector3( # top left front
			walls_map["right_base_top"]['x'] + (crate_width / 2),
			walls_map["right_middle"]['y'] + walls_map["right_middle"]['height'] + (crate_height / 2),
			(platform_thickness / 2) - (crate_width / 2)
		),
		Vector3( # bottom right back
			walls_map["right_most_wall"]['x'] - (crate_width / 2),
			walls_map["right_base_top"]['y'] - (crate_height / 2),
			(-1 * platform_thickness / 2) + (crate_width / 2)
		)
	],
	[ # 6
		Vector3( # top left front
			walls_map["lower_platform"]['x'] + (crate_width / 2),
			walls_map["lower_platform"]['y'] + walls_map["lower_platform"]['height'] + (crate_height / 2),
			(platform_thickness / 2) - (crate_width / 2)
		),
		Vector3( # bottom right back
			walls_map["left_base_bottom"]['x'] + walls_map["left_base_bottom"]['width'] - (crate_width / 2),
			walls_map["left_base_bottom"]['y'] - (crate_height / 2),
			(-1 * platform_thickness / 2) + (crate_width / 2)
		)
	],
	[ # 7
		Vector3( # top left front
			walls_map["right_base_bottom"]['x'] + (crate_width / 2),
			walls_map["lower_platform"]['y'] + walls_map["lower_platform"]['height'] + (crate_height / 2),
			(platform_thickness / 2) - (crate_width / 2)
		),
		Vector3( # bottom right back
			walls_map["right_base_top"]['x'] - (crate_width / 2),
			walls_map["right_base_bottom"]['y'] - (crate_height / 2),
			(-1 * platform_thickness / 2) + (crate_width / 2)
		)
	]
]

func convert_original_point_to_godot_3d(original_point: Vector3) -> Vector3:
	var final_godot_x: float = (original_point.x / ORIGINAL_WIDTH) * target_width
	if CENTER_CONTENT:
		final_godot_x -= target_width / 2.0
	var percent_y = original_point.y / ORIGINAL_HEIGHT
	var final_godot_y: float = (1.0 - percent_y) * target_height # Scale and invert Y
	if CENTER_CONTENT:
		final_godot_y -= target_height / 2.0

	# The Z component is assumed to be the desired final 3D Z position relative to Godot's Z=0
	var final_godot_z: float = original_point.z

	return Vector3(final_godot_x, final_godot_y, final_godot_z)

## Converts the list of spawn area definitions from original coordinates + Z offset
## into a list of areas where all points are in the final Godot 3D world coordinates.
##
## Returns:
##   An Array where each element is an Array like [Vector3(), Vector3()]
##   with Vector3s in the final Godot world space, or an empty array if definitions are missing/invalid.
func get_spawn_areas_godot_coords() -> Array:
	var godot_areas_list = []

	for area_points in spawn_pos:
		if not (area_points is Array and area_points.size() == 2 and
				area_points[0] is Vector3 and area_points[1] is Vector3):
			push_warning("Skipping invalid spawn area definition format in GameConfig: ", area_points)
			continue

		var point1_orig = area_points[0]
		var point2_orig = area_points[1]

		# Convert each point using the helper function
		var point1_godot = convert_original_point_to_godot_3d(point1_orig)
		var point2_godot = convert_original_point_to_godot_3d(point2_orig)

		godot_areas_list.append([point1_godot, point2_godot])

	return godot_areas_list

func get_random_point_in_areas(areas_list_godot_coords: Array) -> Vector3:
	# Check if the list of areas is empty or invalid
	if areas_list_godot_coords == null or areas_list_godot_coords.is_empty():
		push_warning("Areas list (in Godot coords) is empty. Cannot pick a random point.")

	# 1. Pick a random area from the list
	var random_area_index = randi_range(0, areas_list_godot_coords.size() - 1)
	# print("Random area index: ", random_area_index)
	var selected_area_godot = areas_list_godot_coords[random_area_index]

	# Basic check for valid area format
	if not (selected_area_godot is Array and selected_area_godot.size() == 2 and
			selected_area_godot[0] is Vector3 and selected_area_godot[1] is Vector3):
		push_error("Invalid Godot area format detected at index ", random_area_index, ". Expected [Vector3, Vector3].")

	# Get the two defining corners of the selected area (they are already in Godot coords)
	var corner1_godot: Vector3 = selected_area_godot[0]
	var corner2_godot: Vector3 = selected_area_godot[1]

	# 2. Calculate the minimum and maximum coordinates for each axis (forming the AABB)
	# We use min() and max() because the corners can be given in any order.
	var min_x = min(corner1_godot.x, corner2_godot.x)
	var max_x = max(corner1_godot.x, corner2_godot.x)
	var min_y = min(corner1_godot.y, corner2_godot.y)
	var max_y = max(corner1_godot.y, corner2_godot.y)
	var min_z = min(corner1_godot.z, corner2_godot.z)
	var max_z = max(corner1_godot.z, corner2_godot.z)

	# 3. Generate a random floating-point number for each axis within its min/max range
	var random_x = randf_range(min_x, max_x)
	var random_y = randf_range(min_y, max_y)
	var random_z = randf_range(min_z, max_z)

	# Return the generated random point
	return Vector3(random_x, random_y, random_z)

var PLAYER_LAYER: int = 2
var WALL_LAYER: int = 1
var ENEMIES_LAYER: int = 3
var CRATE_LAYER: int = 4
var STANDARD_BULLETS_LAYER: int = 5
var DISC_GUN_BULLET: int = 6

enum EntityType { PLAYER, CRATE, ENEMY }

# weapons

@export var ORIGINAL_PISTOL_BULLET_SIZE: float = 4
var pistol_bullet_size: float = ORIGINAL_PISTOL_BULLET_SIZE * SCALE_FACTOR

@export var ORIGINAL_LAZER_TIP_HEIGHT: float = 5
var lazer_tip_height: float = ORIGINAL_LAZER_TIP_HEIGHT * SCALE_FACTOR

@export var ORIGINAL_GRENADE_SIZE: float = 3
var grenade_size: float = ORIGINAL_GRENADE_SIZE * SCALE_FACTOR

@export var ORIGINAL_MINE_WIDTH: float = 8
var mine_width: float = ORIGINAL_MINE_WIDTH * SCALE_FACTOR
var max_deploy_angle_deviation_deg: float = 80.0 # from straight down
var max_ray_dist: float = 100.0 # max distance to check for ground

@export var ORIGINAL_MINE_HEIGHT: float = 5
var mine_height = ORIGINAL_MINE_HEIGHT * SCALE_FACTOR
@export var MINE_ACTIVATION_DELAY: float = 0.5

@export var ORIGINAL_BAZOOKA_BULLET_WIDTH: float = 5
var bazooka_bullet_width = ORIGINAL_BAZOOKA_BULLET_WIDTH * SCALE_FACTOR

@export var ORIGINAL_BAZOOKA_BULLET_HEIGHT: float = 4
var bazooka_bullet_height = ORIGINAL_BAZOOKA_BULLET_HEIGHT * SCALE_FACTOR

func _ready():
	print("target ratio ", target_ratio)
	print("target width ", target_width)
	print("target height ", target_height)
