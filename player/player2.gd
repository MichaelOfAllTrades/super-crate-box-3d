# player.gd

extends CharacterBody3D

# --- Movement Variables ---
var walk_speed: float = GameConfig.player_x_speed
@export var fly_speed: float = 10.0
@export var jump_velocity: float = 4.5
@export var sensitivity: float = 0.003 # Mouse sensitivity

# --- Physics ---
# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
#var gravity: float = 600.0

var jump_time: int = 0
var max_jump_time: int = 7
var jump_initial_velocity: float = 200.0 # 16, 600
var jump_sustain_velocity: float = 100.0 # 100
var gravity: float = 38.0 # 5
var is_jumping: bool = false
var jump_held: bool = false


# --- State ---
enum MovementMode { NORMAL, FLY }
var current_mode: MovementMode = MovementMode.NORMAL
var target_velocity: Vector3 = Vector3.ZERO

# game over
var is_game_over: bool = false
@export var start_position: Vector3 = Vector3.ZERO
@export var start_rotation: Vector3 = Vector3.ZERO
# game over initial collision settings (store original values)
var _initial_collision_layer: int
var _initial_collision_mask: int



# --- Node References ---
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D


# --- Weapon Stuff ---
@export var weapon_resources: Array[WeaponResource] = [] # Assign in Inspector
@onready var weapon_holder: Node3D = $Head/WeaponHolder
var current_weapon_index: int = -1
var current_weapon_resource: WeaponResource = null
var current_weapon_visual_node: Node3D = null
var current_weapon_logic_script: BaseWeaponLogic = null # Reference to the logic script


# --- Mine Stuff ---
var mine_active: bool = false
var _can_deploy_at_current_shadow_pos: bool = false # Cam angle is high enough to render mine shadow

# reference to laser charge indicator in HUD
# @onready var laser_charge_indicator = $CanvasLayer/LaserChargeIndicator
# @onready var hud_node = $CanvasLayer/HUD

# ... (Rear view variables/setup if still needed for Dual Pistols) ...
@export var rear_view_enabled: bool = false # Control via dual pistol logic
@export var rear_view_size: Vector2 = Vector2(320, 180) # Variable size
@export var rear_view_position: Vector2 = Vector2(10, 10) # Variable position
var rear_camera: Camera3D = null
var subviewport_container: SubViewportContainer = null
var subviewport: SubViewport = null

# signal teleport_crate
signal minimap_update(entity_id, entity_type, position_2d)
var MY_TYPE = GameConfig.EntityType.PLAYER

func _ready():
	add_to_group("player")
	# Hide and capture the cursor for FPS controls
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# ... (mouse capture, rear view setup) ...
	if weapon_resources.size() > 0:
		switch_weapon(0)
	else:
		print("No weapon resource assigned to player!")
	
	# Setup Rear View references
	rear_camera = $RearCamera # Assuming it's direct child of Player
	subviewport_container = $CanvasLayer/RearViewContainer
	subviewport = $CanvasLayer/RearViewContainer/RearViewport
	if rear_camera and subviewport_container and subviewport:
		# Assign the rear camera to the subviewport
		subviewport.world_3d = get_world_3d() # Use the same world as the main camera
		# Link camera AFTER setting world_3d seems more reliable sometimes
		# We might need to assign the camera path or instance later if issues arise
		# For now, try direct assignment (may need adjustment)
		# This part is tricky; often needs setting via code or ensuring camera is IN the SubViewport's scene tree.
		# Alternative: Put RearCamera INSIDE RearViewport node. Let's try that first.
		
		# --- REVISED SETUP for Rear View ---
		# 1. In player.tscn, move RearCamera node to be a CHILD of RearViewport node.
		# 2. The code below assumes this structure.
		
		rear_camera = $CanvasLayer/RearViewContainer/RearViewport/RearCamera
		
		# Apply initial size and position from exported vars
		subviewport_container.size = rear_view_size
		subviewport_container.position = rear_view_position
		subviewport_container.visible = rear_view_enabled # Initially hidden unless set
		
		# Ensure SubViewport fills its container
		subviewport.size = rear_view_size # Match container initially
		subviewport_container.stretch = true # Allows viewport to scale within container
	else:
		printerr("Rear view nodes not found correctly!")
	
	# trying smthn regarding crate
	GameEvents.connect("crate_collected", Callable(self, "player_on_crate_collected"))

	_initial_collision_layer = collision_layer
	_initial_collision_mask = collision_mask
	# game over
	if not is_game_over:
		_reset_player_state()

func player_on_crate_collected(_crate_node):
	# call switch weapon with random number
	print("Crate collected, switching to random weapon!")
	# Randomly select a weapon index
	var random_index = randi() % weapon_resources.size()

	switch_weapon(random_index)

func _unhandled_input(event: InputEvent):
	# print("Unhandled input event: ", event)
	# check for "restart" input IFF is_game_over is true
	if is_game_over and event.is_action_just_pressed("restart"):
		_restart_game()
		return
	# block input during game over
	if is_game_over:
		return
	
	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# print("MOUSE GOING ", event.relative.x, " ", event.relative.y)
		# Rotate player left/right (around Y axis)
		self.rotate_y(-event.relative.x * sensitivity)
		# Rotate camera up/down (around X axis) - Clamped
		head.rotate_x(-event.relative.y * sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"): # Esc key
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Recapture on click
		
	# Toggle Movement Mode
	if event.is_action_pressed("fly_mode_key"): # '2' key
		if current_mode == MovementMode.NORMAL:
			current_mode = MovementMode.FLY
			#print("Switched to Fly Mode")
		else:
			current_mode = MovementMode.NORMAL
			#print("Switched to Normal Mode")
	
	## --- TEMP: Direct Fly Toggle with 'R' for testing ---
	#if event.is_action_just_pressed("fly_toggle"): # 'R' key
		#if current_mode == MovementMode.NORMAL:
			#current_mode = MovementMode.FLY
			#print("Toggled Fly Mode ON (R)")
		#else:
			#current_mode = MovementMode.NORMAL
			#print("Toggled Fly Mode OFF (R)")
	## --- End TEMP ---
	
	# Weapon Switching Input
	if Input.is_action_just_pressed("pistol"):
		switch_weapon(0)
	if Input.is_action_just_pressed("dual pistol"):
		switch_weapon(1)
	if Input.is_action_just_pressed("machine gun"):
		switch_weapon(2)
	if Input.is_action_just_pressed("minigun"):
		switch_weapon(3)
	if Input.is_action_just_pressed("revolver"):
		switch_weapon(4)
	if Input.is_action_just_pressed("shotgun"):
		switch_weapon(5)
	if Input.is_action_just_pressed("bazooka"):
		switch_weapon(6)
	if Input.is_action_just_pressed("lazer rifle"):
		switch_weapon(7)
	if Input.is_action_just_pressed("mine"):
		switch_weapon(8)
	
	if Input.is_action_just_pressed("crate"):
		# print("Teleporting crate!")
		var crates = get_tree().get_nodes_in_group("crates")
		if crates.size() > 0:
			var crate_node = crates[0] as CharacterBody3D
			if crate_node and crate_node.has_method("teleport_and_collect"):
				crate_node.teleport_and_collect()
		emit_signal("teleport_crate")

	
	# Check for fire input ONLY (logic moved to weapon script)
	if Input.is_action_pressed("shoot"):
		if current_weapon_logic_script:
			current_weapon_logic_script.try_fire()
	
	# Check for fire release (for weapons that aren't automatic
	if Input.is_action_just_released("shoot"):
		if current_weapon_logic_script:
			current_weapon_logic_script.on_fire_input_released()

func switch_weapon(index: int):
	if index < 0 or index >= weapon_resources.size(): return
	if index == current_weapon_index: return

	if index == 8:
		mine_active = true
	else:
		mine_active = false
		MineRaycastEvents.mine_shadow_update.emit(Transform3D.IDENTITY, false) # Hide shadow

	# --- Unequip Old Weapon ---
	if current_weapon_logic_script:
		current_weapon_logic_script.unequip()
	if current_weapon_visual_node:
		current_weapon_visual_node.queue_free()
		current_weapon_visual_node = null
		current_weapon_logic_script = null

	# --- Equip New Weapon ---
	current_weapon_index = index
	current_weapon_resource = weapon_resources[current_weapon_index]

	if not current_weapon_resource or not current_weapon_resource.weapon_visual_scene:
		printerr("Invalid weapon resource or visual scene for index: ", index)
		current_weapon_index = -1
		current_weapon_resource = null
		return

	#print("Switching to weapon: ", current_weapon_resource.weapon_name)

	# Instantiate visual scene
	current_weapon_visual_node = current_weapon_resource.weapon_visual_scene.instantiate()
	weapon_holder.add_child(current_weapon_visual_node)

	# Find the logic script attached (assuming it's on the root of the visual scene)
	current_weapon_logic_script = current_weapon_visual_node.get_node_or_null("WeaponLogic") as BaseWeaponLogic
	# NOTE: The node containing the script MUST be named "WeaponLogic" OR be the root and have the script directly attached.
	# If script is on the root: current_weapon_logic_script = current_weapon_visual_node as BaseWeaponLogic 
	# Let's assume you add a child Node named "WeaponLogic" to your visual scenes and attach the script there.

	if current_weapon_logic_script:
		# Pass references the weapon script might need
		current_weapon_logic_script.player_reference = self
		current_weapon_logic_script.muzzle_reference = current_weapon_visual_node.get_node_or_null("Muzzle") as Marker3D # Find Muzzle within the visual node
		current_weapon_logic_script.equip() # Notify script it's equipped
		print("Weapon logic script found and configured.")
	else:
		printerr("!!! Failed to find BaseWeaponLogic script on visual node: ", current_weapon_visual_node.name)
		# Clean up partially created weapon
		current_weapon_visual_node.queue_free()
		current_weapon_visual_node = null
		current_weapon_index = -1
		current_weapon_resource = null
		return # Stop equip process

	# Update text label (assuming Label3D is still direct child of visual node root)
	var label = current_weapon_visual_node.get_node_or_null("Label3D") as Label3D
	if label:
		label.text = current_weapon_resource.display_text
		
	# Handle Dual Pistol Rear View specifically if needed
	# rear_view_enabled = (current_weapon_resource.weapon_name == "Dual Pistols")
	# if subviewport_container: subviewport_container.visible = rear_view_enabled

	if index == 8:
		mine_active = true
		if current_weapon_logic_script.has_method("_on_weapon_equipped"):
			current_weapon_logic_script._on_weapon_equipped()
	else:
		mine_active = false
		if current_weapon_logic_script.has_method("_on_weapon_unequipped"):
			current_weapon_logic_script._on_weapon_unequipped()
			MineRaycastEvents.mine_shadow_update.emit(Transform3D.IDENTITY, false) # Hide shadow

func _physics_process(delta: float):
	# game over
	if is_game_over:
		velocity = Vector3.ZERO
		target_velocity = Vector3.ZERO
		return

	# --- Calculate Movement Direction ---
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	# Transform direction based on player's rotation (basis vectors)
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#print("player jump time ", jump_time)
	# --- Handle Velocity based on Mode ---
	if current_mode == MovementMode.NORMAL:
		# Apply gravity
		#print("player on floor? ", is_on_floor())
		var jump_pressed: bool = Input.is_action_pressed("jump")
		if not jump_pressed:
			jump_time = 0
		#print("player jumping? ", jump_pressed)
		
		if is_on_floor():
			target_velocity.y = 0
			
			if jump_pressed:
				#print("")
				#print("")
				#print("player jump pressed")
				is_jumping = true
				jump_time = 0
				target_velocity.y = jump_initial_velocity
			jump_held = jump_pressed
		else:
			#print("player not on floor, jumping? ", is_jumping)
			if is_jumping:
				#print("player not on floor, and is jumping ", jump_pressed, " ", jump_time, " ", max_jump_time)
				if jump_pressed and jump_time < max_jump_time:
					target_velocity.y += jump_sustain_velocity
					jump_time += 1
				else:
					is_jumping = false
			target_velocity.y = max(target_velocity.y - gravity, -200)
			
			if not jump_pressed:
				jump_held = false
				is_jumping = false
		
		if is_on_ceiling():
			#print("player in on ceiling")
			target_velocity.y = 0
			is_jumping = false
		
		#print("player target velocity ", target_velocity)
		
		#if not is_on_floor():
			#target_velocity.y -= gravity * delta
		#else:
			## Reset vertical velocity slightly below zero to help stick to slopes
			#if target_velocity.y < 0:
				#target_velocity.y = -0.1
		#
		## Handle Jump
		#if Input.is_action_just_pressed("jump") and is_on_floor():
			#target_velocity.y = jump_velocity
		
		# Horizontal Velocity
		if direction:
			target_velocity.x = direction.x * walk_speed
			target_velocity.z = direction.z * walk_speed
		else:
			# Apply friction/damping if no input
			target_velocity.x = move_toward(target_velocity.x, 0, walk_speed)
			target_velocity.z = move_toward(target_velocity.z, 0, walk_speed)
	
	elif current_mode == MovementMode.FLY:
		# No gravity in fly mode
		target_velocity = Vector3.ZERO 
		
		# Get fly direction based on camera view
		var fly_direction: Vector3 = -camera.global_transform.basis.z # Forward vector of camera
		
		# Basic Fly Controls (can be expanded)
		if Input.is_action_pressed("move_forward"):
			target_velocity += fly_direction * fly_speed
		if Input.is_action_pressed("move_backward"):
			target_velocity -= fly_direction * fly_speed
		if Input.is_action_pressed("move_left"):
			target_velocity -= camera.global_transform.basis.x * fly_speed # Left vector
		if Input.is_action_pressed("move_right"):
			target_velocity += camera.global_transform.basis.x * fly_speed # Right vector
		if Input.is_action_pressed("jump"): # Fly Up
			target_velocity += Vector3.UP * fly_speed
		# Add a key for flying down if needed (e.g., Shift or C)
		if Input.is_action_pressed("fly_down"):
			target_velocity += Vector3.DOWN * fly_speed
	
	# --- Apply Movement ---
	velocity = target_velocity
	move_and_slide()
	#var collision_info = move_and_collide(velocity * delta)
	# Update target_velocity after move_and_slide for next frame's gravity/friction calc
	#if collision_info:
		#var collider = collision_info.get_collider()
		#print("player collision layer ", collider.collision_layer)


	if get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider:
				if collider.get_collision_layer() & (1 << 2):
					# print("PLAYER DIES")
					pass
			# print("player collision ", collision, " ", collision.get_collider(), " ", collision.get_collider().get_collision_layer())
			# if collision.get_collider().get_collision_layer() & GameConfig.CRATE_LAYER != 0:
			# 	var crate = collision.get_collider()
			# 	crate.handle_player_collision()


	target_velocity = velocity
	
	#if current_weapon_resource:
		#if current_weapon_resource.automatic:
			#if Input.is_action_pressed("fire") and can_shoot:
				#shoot()
	
	# Check for fire input ONLY (logic moved to weapon script)
	if Input.is_action_pressed("shoot"): # Use is_action_pressed for automatic weapons
		if current_weapon_logic_script:
			current_weapon_logic_script.try_fire() 
	
	# print("muzzlescope ", current_weapon_logic_script.muzzle_reference.transform.origin)

	var current_pos_3d = global_transform.origin
	var current_pos_2d = Vector2(current_pos_3d.x, current_pos_3d.y)
	MinimapEvents.emit_signal("entity_position_updated", self, "player", current_pos_2d)

	# print("mine active ", mine_active)
	if mine_active:
		_update_mine_shadow_placement()

func _enter_game_over_state():
	if is_game_over:
		return
	
	print("PLAYER DIED _ GAME OVER")
	is_game_over = true

	# disable physics interactions
	collision_layer = 0
	collision_mask = 0

	GameEvents.emit_signal("game_over")
	# I DONT THINK WE NEED THE REST

func _restart_game():
	print("RESTARTING GAME")
	is_game_over = false

	# Reset state variables
	target_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	is_jumping = false
	jump_time = 0
	current_mode = MovementMode.NORMAL # Or whatever default mode you want

	# Reset position and orientation
	global_transform.origin = start_position
	rotation = Vector3.ZERO # Reset player body rotation
	head.rotation = Vector3.ZERO # Reset camera pitch

	# Re-enable physics interactions
	collision_layer = _initial_collision_layer
	collision_mask = _initial_collision_mask
	# collision_shape.disabled = false # Re-enable if you disabled it

	# Make player visible again
	# mesh_instance.visible = true
	if current_weapon_visual_node:
		current_weapon_visual_node.visible = true
	# If weapon needs ammo reset etc., do it here or in _reset_player_state

	# Recapture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Signal HUD/Game Manager
	GameEvents.emit_signal("game_restarted")

	# Call reset state to ensure everything is clean
	_reset_player_state()

func _reset_player_state():
	# This function can be used for both initial setup and restart
	# Reset health, ammo, specific weapon states etc. if needed later
	velocity = Vector3.ZERO
	target_velocity = Vector3.ZERO
	is_jumping = false
	jump_time = 0

	# Make sure visuals and collision are enabled (handles case where game starts directly)
	# mesh_instance.visible = true
	if current_weapon_visual_node:
		current_weapon_visual_node.visible = true
	collision_layer = _initial_collision_layer
	collision_mask = _initial_collision_mask
	# collision_shape.disabled = false

	# Maybe switch back to default weapon?
	# switch_weapon(0) # Uncomment if you want to always restart with the first weapon

func _update_mine_shadow_placement():
	# print("MINE SHADOW PLACEMENT")
	# # Emit signal to update mine shadow position
	# var target_transform = get_muzzle_global_transform()
	# var can_deploy = true # Placeholder for actual deployment check
	# MineRaycastEvents.emit_signal("mine_shadow_update", target_transform, can_deploy)

	# # Check for mine deployment request
	# if Input.is_action_just_pressed("deploy_mine"):
	# 	MineRaycastEvents.emit_signal("mine_deploy_requested", target_transform)
	if not camera:
		printerr("Camera not found!")
		return
	# 1. Angle Check
	var head_pitch_rad = camera.global_rotation.x
	var angle_from_straight_down_rad = abs(head_pitch_rad - (-PI / 2.0))
	# print("angle from straight down ", angle_from_straight_down_rad)
	# print("angle from straight down deg ", deg_to_rad(GameConfig.max_deploy_angle_deviation_deg))
	if angle_from_straight_down_rad > deg_to_rad(GameConfig.max_deploy_angle_deviation_deg):
		MineRaycastEvents.mine_shadow_update.emit(Transform3D.IDENTITY, false)
		_can_deploy_at_current_shadow_pos = false
		return
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = camera.global_transform.origin
	query.to = query.from + camera.global_transform.basis.z * -GameConfig.max_ray_dist
	query.exclude = [self.get_rid()] # Exclude player

	var main_hit_result = space_state.intersect_ray(query)
	# print("main hit result ", main_hit_result)

	if not main_hit_result:
		MineRaycastEvents.mine_shadow_update.emit(Transform3D.IDENTITY, false)
		_can_deploy_at_current_shadow_pos = false
		return
	
	# 2. Check if the rayast hit a wall
	var collider = main_hit_result.collider
	# print("collider ", collider.name, " ", collider.is_in_group("wall"), GameConfig.walls_set.has(collider.name))
	if not collider or not GameConfig.walls_set.has(collider.name):
		MineRaycastEvents.mine_shadow_update.emit(Transform3D.IDENTITY, false)
		_can_deploy_at_current_shadow_pos = false
		return
	
	var normal: Vector3 = main_hit_result.normal
	# 3. Check if the raycast hit a horizontal surface
	# print("normal ", normal)
	if normal.y < 0.5:
		MineRaycastEvents.mine_shadow_update.emit(Transform3D.IDENTITY, false)
		_can_deploy_at_current_shadow_pos = false
		return
	
	var potential_pos: Vector3 = main_hit_result.position
	var final_offset_from_walls: Vector3 = Vector3.ZERO
	# print("potential pos ", potential_pos)
	# print("final offset from walls ", final_offset_from_walls)
	
	# Directions parallel to the hit surface (aproximate for near-horizontal)
	var planar_directions = [
		Vector3.RIGHT.slide(normal).normalized(),
		Vector3.LEFT.slide(normal).normalized(),
		Vector3.FORWARD.slide(normal).normalized(),
		Vector3.BACK.slide(normal).normalized()
	]
	# print("planar directions ", planar_directions)

	var push_vectors = []

	for dir in planar_directions:
		if dir.is_zero_approx(): continue # Skip if direction is invalid

		var side_query = PhysicsRayQueryParameters3D.new()
		side_query.from = potential_pos + normal * 0.05
		side_query.to = side_query.from + dir * 5.0 # CHANGE LATER
		side_query.exclude = [self.get_rid()] # Exclude player

		var side_hit_result = space_state.intersect_ray(side_query)

		if side_hit_result:
			var wall_collider = side_hit_result.collider
			# Check if it hit a wall
			if wall_collider and GameConfig.walls_set.has(wall_collider.name):
				var wall_normal: Vector3 = side_hit_result.normal
				# Check if normal is vertical on either z or x axis
				if abs(wall_normal.dot(Vector3.UP)) < 0.15:
					var dist_to_wall = (side_hit_result.position - side_query.from).length()

					if dist_to_wall < 0.5: # CHANGE LATER
						var penetration = 0.5 - dist_to_wall
						push_vectors.append(-dir * penetration)
	# print("push vectors ", push_vectors)
	# Combine the push vectors, this works for corners too
	for pv in push_vectors:
		final_offset_from_walls += pv
	
	var final_pos = potential_pos + final_offset_from_walls
	final_pos.y += GameConfig.mine_height / 2.0
	# print("final pos ", final_pos)

	# Final Ground Snap
	var target_transform = Transform3D(Basis(), final_pos)
	MineRaycastEvents.mine_shadow_update.emit(target_transform, true)
	_can_deploy_at_current_shadow_pos = true

func _exit_tree() -> void:
	MinimapEvents.emit_signal("entity_removed", self)
