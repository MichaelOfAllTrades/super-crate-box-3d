# BazookaWeapon.gd
@tool # Allows properties to update in editor potentially
class_name BazookaWeapon
extends BaseWeaponLogic

@export var bullet_scene: PackedScene # Assign bazooka_bullet.tscn

# Override the base fire method
func fire():
	if not bullet_scene:
		printerr("BazookaWeapon: Bullet scene not assigned!")
		return
	
	print("Bazooka firing!")
	var spawn_transform = get_muzzle_global_transform()
	print("bazooka spawn transform: ", spawn_transform)

	var bullet_instance = bullet_scene.instantiate()
	# Add to main scene tree (get_tree().root is simple way)
	get_tree().root.add_child(bullet_instance) 

	# Set bullet properties (assuming bullet script has these methods/vars)
	if bullet_instance.has_method("set_initial_direction"):
		bullet_instance.set_initial_direction(spawn_transform)
	# Example: Override speed if needed
	# if bullet_instance.has_variable("speed"): bullet_instance.speed = 50.0
