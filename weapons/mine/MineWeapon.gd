# MineWeapon.gd
@tool # Allows properties to update in editor potentially
class_name MineWeapon
extends BaseWeaponLogic

@export var mine_shadow_scene: PackedScene # Assign mine_shadow.tscn
@export var mine_deployed_scene: PackedScene # Assign mine_deployed.tscn
@export var explosion_scene: PackedScene # Assign explosion.tscn
@export var mine_wait: float = 1.0 # Time before mine can be triggered

var _shadow_instance: Node3D

func _ready() -> void:
	if mine_shadow_scene:
		_shadow_instance = mine_shadow_scene.instantiate()
		print("MineWeapon: Mine shadow instance created")
		get_tree().root.add_child(_shadow_instance)
		_shadow_instance.hide()
	else:
		printerr("MineWeapon: Mine shadow scene not assigned!")

func _exit_tree() -> void:
	if is_instance_valid(_shadow_instance):
		_shadow_instance.queue_free()
	_on_weapon_unequipped()

# Override the base fire method
# func fire():
# 	if not mine_deployed:
# 		printerr("MineWeapon: Mine deployed scene not assigned!")
# 		return

# Called by Player.gd when weapon is equipped
func _on_weapon_equipped():
	print("MineWeaponLogic: Equipped")
	if not MineRaycastEvents.mine_shadow_update.is_connected(_on_mine_shadow_update):
		MineRaycastEvents.mine_shadow_update.connect(_on_mine_shadow_update.bind(self))
	if not MineRaycastEvents.mine_deploy_requested.is_connected(_on_mine_deploy_requested.bind(self)):
		MineRaycastEvents.mine_deploy_requested.connect(_on_mine_deploy_requested.bind(self))
	# Shadow will appear/update when Player.gd emits next signal

# Called by Player.gd when weapon is unequipped
func _on_weapon_unequipped():
	print("MineWeaponLogic: Unequipped")
	if MineRaycastEvents.mine_shadow_update.is_connected(_on_mine_shadow_update):
		MineRaycastEvents.mine_shadow_update.disconnect(_on_mine_shadow_update)
	if MineRaycastEvents.mine_deploy_requested.is_connected(_on_mine_deploy_requested):
		MineRaycastEvents.mine_deploy_requested.disconnect(_on_mine_deploy_requested)

	if is_instance_valid(_shadow_instance):
		_shadow_instance.hide()

# func _on_mine_shadow_update(weapon_logic_self, target_transform: Transform3D, can_deploy: bool):
func _on_mine_shadow_update(target_transform: Transform3D, can_deploy: bool, weapon_logic_self):
	print("on mine shadow update")
	if weapon_logic_self != self: return # Ensure correct instance if multiple exist somehow (shouldn't for active weapon)
	if not is_instance_valid(_shadow_instance): return

	if can_deploy:
		_shadow_instance.global_transform = target_transform
		_shadow_instance.show()
	else:
		_shadow_instance.hide()

func _on_mine_deploy_requested(weapon_logic_self, deploy_transform: Transform3D):
	if weapon_logic_self != self: return 

	# Player already checked can_fire() from BaseWeaponLogic before emitting.
	# This function now IS the "fire" action for the mine.
	if not mine_deployed_scene:
		printerr("MineWeaponLogic: Mine deployed scene not assigned!")
		return

	var mine_instance = mine_deployed_scene.instantiate()
	get_tree().root.add_child(mine_instance) 
	mine_instance.global_transform = deploy_transform
	
	# print("Mine deployed at: ", deploy_transform.origin)
	
	# Trigger the cooldown mechanism from BaseWeaponLogic
	# Assuming BaseWeaponLogic has a method like this to be called by subclasses post-fire action
	# if has_method("_start_cooldown"): 
	# 	_start_cooldown() 
	# Or if BaseWeaponLogic's fire() itself handles cooldown and expects to be called:
	# super.fire() // if BaseWeaponLogic.fire() only handles cooldown and doesn't shoot

	# Hide shadow temporarily; Player.gd will update it on next frame if still valid
	if is_instance_valid(_shadow_instance):
		_shadow_instance.hide()


# Override the base fire method - it's not directly used by player for mine deployment anymore,
# as player uses signals. But good to have a clear behavior.
func fire():
	# This could be called if some other system tries to fire the weapon directly.
	# For the mine, deployment relies on a valid transform from player's raycast.
	# print("MineWeaponLogic.fire() called directly. Mine deployment is typically via MineRaycastEvents.mine_deploy_requested.")
	# Optionally, you could try to use the last known good shadow position if available,
	# but it's cleaner to rely on the player-driven signal flow.
	pass