# LazerRifleWeapon.gd
@tool # Allows properties to update in editor potentially
class_name LazerRifleWeapon
extends BaseWeaponLogic

@export var segment_scene: PackedScene # Assign laser_segment.tscn
@export var tip_mesh_scene: PackedScene # Optional: A scene for the temporary tip mesh
@export var charge_time: float = 0.8
@export var segment_count: int = 50
@export var segment_spacing: float = 1.0 # Distance between segment starts

var is_charging: bool = false
var charge_start_time: float = 0.0
var fire_transform: Transform3D # Transform when fire was initiated
var temp_tip_instance: Node3D = null

func _ready():
	fire_rate = charge_time # Ensure cooldown matches charge time

# signals
signal charge_started(max_charge_time: float)
# signal charge_progress(current_charge_ratio: float)
signal charge_fired

# Override the base fire method
func fire():
	if is_charging: return # Already charging
	
	# print("Laser charging...")
	is_charging = true
	charge_start_time = Time.get_ticks_msec() / 1000.0
	fire_transform = get_muzzle_global_transform() # Store initial transform
	# change fire_transform's 'y' value to be 5 less
	fire_transform.origin.y -= 1.0

	# EMIT THE GLOBAL SIGNAL THAT CHARGING HAS STARTED
	GameEvents.lazer_charging_started.emit()
	
	# Show temporary tip # WE AREN'T DOING THIS ANYMORE
	if tip_mesh_scene and not is_instance_valid(temp_tip_instance):
		temp_tip_instance = tip_mesh_scene.instantiate()
		# 
		temp_tip_instance.transform.origin = fire_transform.origin # Position at muzzle
		add_child(temp_tip_instance) # Add as child of WeaponLogic node
	# 	# Position it relative to muzzle (will be updated in process)
	set_process(true) # Start updating tip position

func _process(delta: float):
	if is_charging:
		# Update temp tip position to follow muzzle
		if is_instance_valid(temp_tip_instance):
			fire_transform = get_muzzle_global_transform()
			fire_transform.origin.y -= 1.0
			temp_tip_instance.global_transform = fire_transform
		
		# Check if charge time elapsed
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - charge_start_time >= charge_time:
			fire_transform = get_muzzle_global_transform() # Get transform just as we fire beam
			# _fire_beam()
			# is_charging = false
			_stop_charging(true) # Fire the beam
			set_process(false) # Stop updating tip
		
		# emit signal
		# charge_started.emit(charge_time)

func _stop_charging(did_fire: bool):
	if not is_charging: return # Not charging, nothing to stop
	is_charging = false
	set_process(false) # Stop updating tip
	GameEvents.lazer_charging_stoppped.emit() # Emit signal for stopping charge

	if is_instance_valid(temp_tip_instance):
		temp_tip_instance.queue_free()
		temp_tip_instance = null

	if did_fire:
		fire_transform = get_muzzle_global_transform() # Get transform just as we fire beam
		_fire_beam()


func _fire_beam():
	# emit signal to STOP charging
	charge_fired.emit()

	# print("Lazer Firing Beam!")
	# Remove temp tip
	if is_instance_valid(temp_tip_instance):
		temp_tip_instance.queue_free()
		temp_tip_instance = null
	if not segment_scene:
		printerr("LazerWeapon: Segment scene not assigned")
		return
	
	var start_pos = fire_transform.origin
	var direction = -fire_transform.basis.z.normalized() # Forward direction at time of fire
	
	for i in range(2, segment_count):
		var segment_instance = segment_scene.instantiate()
		segment_instance.transform.origin.y = GameConfig.lazer_tip_height
		# print("laser rifle segment instance y ", segment_instance.transform.origin.y)
		segment_instance.transform.origin.z = GameConfig.lazer_tip_height
		get_tree().root.add_child(segment_instance)
		
		# Position and orient each segment
		var segment_pos = start_pos + direction * segment_spacing * i
		var segment_transform = fire_transform.looking_at(segment_pos + direction, Vector3.UP)
		segment_transform.origin = segment_pos
		segment_instance.global_transform = segment_transform
		#segment_instance.look_at(segment_pos + direction, Vector3.UP) # Alternative orientation
		#segment_instance.global_position = segment_pos

func unequip():
	# Ensure charging stops and tip removed if weapon unequipped mid-charge
	# WAIT WE DONT WANT THIS, FIX LATER
	if is_charging:
		is_charging = false
		set_process(false)
		if is_instance_valid(temp_tip_instance):
			temp_tip_instance.queue_free()
			temp_tip_instance = null
	super.unequip() # Call base class method
