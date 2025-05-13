extends CharacterBody3D

# Speed variables that can be modified externally
var x_speed: float = GameConfig.small_enemy_speed_slow
var y_speed: float = 20.0
var y_accel: float = -18.0
var z_speed: float = 0.0

# Gravity settings
@export var gravity_enabled: bool = true
@export var gravity_acceleration: float = 9.8
@export var terminal_velocity: float = 20.02

var enemy_label: String = ""

# Movement enabled flag
var movement_enabled: bool = true

# Ground check
var is_on_floor: bool = false
@export var floor_detection_distance: float = 0.1

# Reference to a debug label (optional)
@export var debug_label: Label3D = null

# Raycasting for floor detection
var ray_cast: RayCast3D

# References to child nodes (assigned in _ready)
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var health: int = 1

var fell: bool = false

func _ready():
	if mesh_instance and mesh_instance.mesh is BoxMesh and collision_shape and collision_shape.shape is BoxShape3D:
		# BoxMesh size is full extent (width, height, depth)
		# BoxShape3D size is also full extent
		var new_size = Vector3(GameConfig.small_enemy_width, GameConfig.small_enemy_height, GameConfig.small_enemy_width)
		
		# Update Mesh Size
		mesh_instance.mesh.size = new_size
		
		# Update Collision Shape Size
		collision_shape.shape.size = new_size
	# print(enemy_label, " y ", self.transform.origin.y)
	
	#self.set_floor_constant_speed_enabled(true)
	
	# Create a raycast for floor detection
	ray_cast = RayCast3D.new()
	add_child(ray_cast)
	
	# Configure the raycast to point downward
	ray_cast.target_position = Vector3(0, -floor_detection_distance - 0.1, 0)
	ray_cast.enabled = true
	ray_cast.position = Vector3(0, 0, 0)
	#print("small enemy 2 speed slow", GameConfig.small_enemy_speed_slow)

func _physics_process(delta):
	if !movement_enabled:
		return
	
	# Check if we're on the floor
	#is_on_floor = ray_cast.is_colliding()
	#print(self.enemy_label, " is on floor? ", is_on_floor)

	# Apply gravity if enabled and not on floor
	#if gravity_enabled and !is_on_floor:
		##y_speed -= gravity_acceleration * delta
		#y_speed += self.y_accel * delta
		#y_speed = max(y_speed, -terminal_velocity)
	#elif is_on_floor and y_speed != 0: # y_speed < 0
		#y_speed = 0
		#print(self.enemy_label, " y speed shoud be 0 exactly ", y_speed)
	#print(self.enemy_label, " y speed ", y_speed)
	#print(self.enemy_label, " x speed ", GameConfig.small_enemy_speed_slow)

	# Store original horizontal speeds
	#var original_x_speed = x_speed
	#var original_z_speed = z_speed
	
	# Create a movement vector from the separate speed components
	var movement = Vector3(x_speed, y_speed, z_speed) * delta
	#print(self.enemy_label, " movement ", movement)
	#print(self.enemy_label, " ", self.transform.origin)
	
	# Move and check for collisions
	var collision = move_and_collide(movement)
	#print(self.enemy_label, " collision ", collision)
	
	var negate: bool = false
	
	# If we hit something
	if collision:
		#print(self.enemy_label, " COLLIDED")
		var collision_normal = collision.get_normal()
		#print(self.enemy_label, " normal ", collision_normal)
		
		if collision_normal.y > 0.7:
			#print(self.enemy_label, " is floor collision ")
			# Handle floor collision - just stop vertical movement
			y_speed = 0
			is_on_floor = true
		else:
			y_speed += y_accel * 5
			#print(self.enemy_label, " y accel ", y_accel)
			#print(self.enemy_label, " y speed ", y_speed)
		
		if abs(collision_normal.x) > 0.7:
			x_speed = -x_speed
		
		if abs(collision_normal.z) > 0.7:
			z_speed = -z_speed
	else:
		# Clear debug info if no collision
		if debug_label:
			debug_label.text = ""
		y_speed += y_accel
	
	# IMPORTANT: Reset horizontal speeds to original values
	# This ensures constant speed regardless of surface friction
	#x_speed = original_x_speed
	#z_speed = original_z_speed
	if negate:
		x_speed *= -1
		z_speed *= -1
	velocity.x = x_speed
	
	if self.transform.origin.y < -1 * ((GameConfig.ORIGINAL_HEIGHT * GameConfig.SCALE_FACTOR) / 2):
		self.transform.origin.y = ((GameConfig.ORIGINAL_HEIGHT * GameConfig.SCALE_FACTOR) / 2) - 30
		if !fell:
			fell = true
			# change enemy speed to GameConfig.small_enemy_speed_fast
			x_speed = GameConfig.small_enemy_speed_fast
			# Create a new material and set its color
			var fast_material = StandardMaterial3D.new()
			fast_material.albedo_color = GameConfig.fast_enemy_color
			mesh_instance.set_surface_override_material(0, fast_material)
	
	# MINIMAP
	var current_pos_3d = global_transform.origin
	var current_pos_2d = Vector2(current_pos_3d.x, current_pos_3d.y)
	MinimapEvents.emit_signal("entity_position_updated", self, "small enemy " + str(fell), current_pos_2d)

func handle_player_collision():
	queue_free() # here the enemy dies, but in real game PLAYER should die

func take_damage(damage):
	print("small enemy just took ", damage, " damage")
	health -= damage
	if health <= 10:
		GameConfig.num_enemies -= 1
		queue_free()

# Functions to control movement from outside
func set_speeds(new_x_speed: float, new_y_speed: float, new_z_speed: float):
	x_speed = new_x_speed
	y_speed = new_y_speed
	z_speed = new_z_speed

func set_x_speed(new_speed: float):
	x_speed = new_speed

func set_y_speed(new_speed: float):
	y_speed = new_speed

func set_z_speed(new_speed: float):
	z_speed = new_speed

func stop_movement():
	x_speed = 0.0
	y_speed = 0.0
	z_speed = 0.0

func _exit_tree():
	print("small enemy 2 exiting tree")
	MinimapEvents.emit_signal("entity_removed", self)