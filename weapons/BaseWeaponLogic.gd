# BaseWeaponLogic.gd
class_name BaseWeaponLogic
extends Node

## Time between allowed shots for this weapon
@export var fire_rate: float = 8.0
## Is the weapon currently cooling down?
var can_fire: bool = true
## Timer node for handling cooldowns
var cooldown_timer: SceneTreeTimer = null

## MUST re-click to fire?
@export var must_reclick: bool = true
## un-clicked?
var needs_release: bool = true

## Reference to the player (set externally, e.g., by Player script)
var player_reference: CharacterBody3D = null
## Reference to the muzzle marker (set externally or @onready)
var muzzle_reference: Marker3D = null

# signals
signal cooldown_started(duration: float)
signal cooldown_finished
signal fired

# Called by the Player script when the fire action is triggered
func try_fire():
	# print("trying to fire ", can_fire)
	if can_fire and (not must_reclick or not needs_release):
		fire() # Call the specific implementation in child class
		start_cooldown()
		if must_reclick:
			# print("must re click, so set unclicekd to false")
			needs_release = true

# This function MUST be implemented by inheriting weapon scripts
func fire():
	push_error("fire() method not implemented in inheriting weapon script!")

func on_fire_input_released():
	needs_release = false
	# print("RELEASED")

# This function MUST be implemented by inheriting weapon scripts
func start_cooldown():
	if fire_rate > 0:
		can_fire = false
		cooldown_timer = get_tree().create_timer(fire_rate, false) 
		cooldown_timer.timeout.connect(_on_cooldown_finished)

# Resets the ability to fire after cooldown
func _on_cooldown_finished():
	can_fire = true
	#cooldown_timer = null # Clear reference

# Optional: Function called when weapon is equipped
func equip():
	can_fire = true # Ensure weapon can fire immediately when equipped
	if cooldown_timer != null: # Cancel any ongoing cooldown from previous equip
		# cooldown_timer.disconnect("timeout", self, "_on_cooldown_finished") # Need Callable now
		# SceneTreeTimers are harder to cancel cleanly this way,
		# relying on can_fire flag is usually sufficient.
		pass
	needs_release = false

# Optional: Function called when weapon is unequipped
func unequip():
	pass # Add cleanup if needed

# Helper to get the muzzle transform safely
func get_muzzle_global_transform() -> Transform3D:
	if is_instance_valid(muzzle_reference):
		return muzzle_reference.global_transform
	else:
		printerr("Muzzle reference invalid in ", self.get_path())
		# Return transform of the node this script is attached to as fallback
		if get_parent() is Node3D:
			return get_parent().global_transform
		else:
			return Transform3D() # Default empty transform
