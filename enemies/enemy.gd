# enemy.gd
extends CharacterBody3D

#@export var SCALE_FACTOR: float = 0.32
#@export var CENTER_CONTENT: bool = true
#const CREATE_PHYSICS: bool = true
#
#const ORIGINAL_WIDTH: float = 960.0
#const ORIGINAL_HEIGHT: float = 640.0
#
#var target_ratio: float = ORIGINAL_WIDTH / ORIGINAL_HEIGHT
#var target_width: float = ORIGINAL_WIDTH * SCALE_FACTOR
#var target_height: float = ORIGINAL_HEIGHT * SCALE_FACTOR

@export var speed: float = 3.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Directions relative to the enemy's local space
var move_direction_xz = Vector3.RIGHT # Start moving right locally
var move_direction_z = Vector3.LEFT # Start moving forward locally
var num_fire = 0

func _ready():
	self.transform.basis.x = Vector3(GameConfig.small_enemy_width, 0.0, 0.0)
	self.transform.basis.z = Vector3(0.0, GameConfig.small_enemy_width, 0.0)
	self.transform.basis.z = Vector3(0.0, 0.0, GameConfig.small_enemy_height)

func _physics_process(delta: float):
	var current_velocity = velocity
	
	self.transform.origin.x += GameConfig.small_enemy_speed_slow
	#self.transform.origin.z += GameConfig.small_enemy_speed_slow
	self.transform.origin.y -= GameConfig.small_enemy_gravity

	# Apply gravity
	#if not is_on_floor():
		##current_velocity.y -= gravity * delta
		#current_velocity.y -= GameConfig.enemy
	#else:
		#if current_velocity.y < 0:
			#current_velocity.y = -0.1 # Stick to floor slightly
#
	## Calculate target horizontal velocity based on current direction
	#var target_velocity_xz = move_direction_xz * speed
	#var target_velocity_z_only = move_direction_z * speed
#
	## Combine velocities - Simple combination for now
	#current_velocity.x = target_velocity_xz.x 
	## Use the Z component from the forward/backward movement
	#current_velocity.z = target_velocity_z_only.z 
#
	## Apply movement
	#set_velocity(current_velocity) # Use set_velocity for CharacterBody3D
	#move_and_slide()

	# Check for collisions AFTER moving
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision:
			var collider = collision.get_collider()
			if collider is StaticBody3D: # Check if we hit a wall/platform
				var normal = collision.get_normal()

				# Reflect based on normal - Check X/Z components predominantly
				if abs(normal.x) > 0.7: # Hit a wall mostly on the side (Left/Right)
					move_direction_xz = move_direction_xz.bounce(normal)
					# Ensure direction is purely horizontal after bounce
					move_direction_xz.y = 0 
					move_direction_xz = move_direction_xz.normalized()
					#print("Bounced XZ: ", move_direction_xz)
				
				if abs(normal.z) > 0.7: # Hit a wall mostly on front/back
					move_direction_z = move_direction_z.bounce(normal)
					# Ensure direction is purely forward/backward
					move_direction_z.x = 0
					move_direction_z.y = 0
					move_direction_z = move_direction_z.normalized()
					#print("Bounced Z: ", move_direction_z)

	# Fall off edges - If no longer on floor after moving forward/backward
	if is_on_floor():
		# Check slightly ahead in the current XZ move direction
		var ground_check_pos = global_transform.origin + move_direction_xz * 0.6 # Check slightly ahead
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(ground_check_pos + Vector3.UP * 0.1, ground_check_pos + Vector3.DOWN * 0.5)
		var result = space_state.intersect_ray(query)
		
		if not result: # No ground ahead in XZ direction
			# Optionally, reverse XZ direction here or implement different logic
			# move_direction_xz *= -1 
			pass # For now, let it fall
	
	if self.transform.origin.y < ((-1 * GameConfig.target_height) / 2) - 50:
		print("ENEMY FELL")
		self.num_fire += 1
		if self.num_fire == 1:
			self.speed *= 1.8
		self.transform.origin.x = 0.0
		self.transform.origin.y = (GameConfig.target_height / 2) - 50
		self.transform.origin.z = 0.0

# Function called by spawner to set initial random direction
func set_initial_direction():
	if randi() % 2 == 0:
		move_direction_xz = Vector3.RIGHT
	else:
		move_direction_xz = Vector3.LEFT
		
	# Optionally randomize initial forward/backward direction too
	# if randi() % 2 == 0:
	#     move_direction_z = Vector3.FORWARD
	# else:
	#     move_direction_z = Vector3.BACKWARD
		
	print("Enemy initial direction XZ: ", move_direction_xz)
