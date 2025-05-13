# enemy_spawner.gd
extends Node3D

#@export var SCALE_FACTOR: float = 0.32
#@export var CENTER_CONTENT: bool = true
#
#const ORIGINAL_WIDTH: float = 960.0
#const ORIGINAL_HEIGHT: float = 640.0
#
#var target_ratio: float = ORIGINAL_WIDTH / ORIGINAL_HEIGHT
#var target_width: float = ORIGINAL_WIDTH * SCALE_FACTOR
#var target_height: float = ORIGINAL_HEIGHT * SCALE_FACTOR
#
@export var small_enemy_scene: PackedScene
@export var big_enemy_scene: PackedScene
#@export var time_between_groups: float = 5.0
#@export var time_between_small_group: float = 0.5

@onready var group_timer: Timer = $GroupTimer
@onready var small_group_timer: Timer = $SmallGroupTimer

var small_group_count: int = 0
var small_group_max: int = 3

# Variable to store data fetched from Level script
var calculated_spawn_position: float = GameConfig.enemy_spawn_pos_y
#var level_script_reference = null # Store the reference

func _ready():
	# print("enemy spawner scale factor ", GameConfig.SCALE_FACTOR)
	# --- Get Reference to the Level Script ---
	# Option A: Using owner (Recommended if spawner is saved within level.tscn)
	#if owner and owner.has_method("get_spawn_parameters"): # Check if owner exists and has the method we need
		#level_script_reference = owner
		#print("Spawner found owner:", owner.name)
	## Option B: Using get_parent() (If spawner is a DIRECT child)
	## elif get_parent() and get_parent().has_method("get_spawn_parameters"):
	##     level_script_reference = get_parent()
	##     print("Spawner found parent:", get_parent().name)
	#else:
		#printerr("Enemy Spawner could not find the Level script via owner or parent!")
		## Optionally disable spawning if level data is crucial
		#set_process(false) 
		#set_physics_process(false)
		#return # Stop _ready processing here

	# --- Fetch Data from Level Script ---
	# Assume Level script has a function to provide needed data
	#var spawn_params = level_script_reference.get_spawn_parameters() 
	#if spawn_params: # Check if data was returned
		#calculated_spawn_position = spawn_params.get("spawn_pos", Vector3.ZERO) # Use .get() for safety
		#print("Spawner received spawn position:", calculated_spawn_position)
		## You could fetch other variables like map_width etc. here too if needed
		## var level_width = spawn_params.get("map_width", 1000.0) 
	#else:
		#printerr("Failed to get spawn parameters from Level script!")
		## Handle error appropriately
	#calculated_spawn_position.y = (GameConfig.target_height / 2) - 50
	#calculated_spawn_position.y = GameConfig.enemy_spawn_pos_y
	#self.transform.origin = calculated_spawn_position
	self.transform.origin = Vector3(0.0, calculated_spawn_position, 0.0)
	# print("spawner y pos ", self.transform.origin.y)

	# Configure timers (as before)
	group_timer.wait_time = GameConfig.time_between_groups
	group_timer.one_shot = false
	group_timer.timeout.connect(_on_group_timer_timeout)

	small_group_timer.wait_time = GameConfig.time_between_small_group
	small_group_timer.one_shot = true
	small_group_timer.timeout.connect(_on_small_group_timer_timeout)

	# Start the timer (as before)
	group_timer.start()

func _on_group_timer_timeout():
	# print("Group Timer Timeout - Spawning new group")
	spawn_group()

func spawn_group():
	if small_enemy_scene == null or big_enemy_scene == null:
		printerr("Enemy scenes not assigned in Spawner!")
		return

	var group_type = 0
	if GameConfig.num_enemies < 3:
		group_type = randi() % 3 # 0: 1 small, 1: 1 big, 2: 3 small
	elif GameConfig.num_enemies < 5:
		group_type = randi() % 2 # 0: 1 small, 1: 1 big
	else:
		group_type = -1 # no more
	#var group_type = 0
	# var group_type = 3

	match group_type:
		0: # Spawn 1 Small
			# print("Spawning Group: 1 Small")
			spawn_enemy(small_enemy_scene)
		1: # Spawn 1 Big
			# print("Spawning Group: 1 Big")
			spawn_enemy(big_enemy_scene)
		2: # Spawn 3 Small (consecutive)
			# print("Spawning Group: 3 Small Consecutive")
			small_group_count = 0
			# Start the sequence by spawning the first small one
			spawn_enemy(small_enemy_scene) 
			small_group_count += 1
			# Start the timer for the *next* small one in the group
			small_group_timer.start() 
		_:
			# print("no enemy")
			pass

func _on_small_group_timer_timeout():
	# print("Small Group Timer Timeout - Spawning next small enemy")
	if small_group_count < small_group_max:
		spawn_enemy(small_enemy_scene)
		small_group_count += 1
		if small_group_count < small_group_max:
			# Start timer again for the next one if more are left
			small_group_timer.start()
	# else:
		# print("Finished spawning 3 small enemies.")


func spawn_enemy(scene_to_spawn: PackedScene):
	GameConfig.num_enemies += 1
	if scene_to_spawn:
		var enemy_instance = scene_to_spawn.instantiate()
		enemy_instance.enemy_label = str(GameConfig.num_enemies)

		# Add to the main level scene tree (use the reference we stored)
		#if level_script_reference:
			#level_script_reference.add_child(enemy_instance) 
		#else:
			## Fallback or error - maybe add to current parent?
			#printerr("Cannot add enemy, no valid level reference!")
		get_parent().add_child(enemy_instance) # Less ideal fallback

		# Set initial position using the fetched value
		# GameConfig.platform_thickness
		var z_position = [0.0, GameConfig.platform_thickness * 0.3, -1 * GameConfig.platform_thickness * 0.3].pick_random()
		enemy_instance.global_position = Vector3(0.0, calculated_spawn_position, z_position)

		if enemy_instance.has_method("set_initial_direction"):
			enemy_instance.set_initial_direction()
			
		#print("Spawned enemy at: ", enemy_instance.global_position) # Debug
	else:
		printerr("Attempted to spawn null enemy scene!")
