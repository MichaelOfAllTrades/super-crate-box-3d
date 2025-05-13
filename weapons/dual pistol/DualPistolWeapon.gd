# DualPistolWeapon.gd
@tool # Allows properties to update in editor potentially
class_name DualPistolWeapon
extends BaseWeaponLogic

@export var bullet_scene: PackedScene # Assign pistol_bullet.tscn

# Override the base fire method
func fire():
	if not bullet_scene:
		printerr("PistolWeapon: Bullet scene not assigned!")
		return
	
	print("Dual Pistol firing!")
	var spawn_transform = get_muzzle_global_transform()
	
	# First bullet - original direction
	var bullet_instance1 = bullet_scene.instantiate()
	get_tree().root.add_child(bullet_instance1) 
	if bullet_instance1.has_method("set_initial_direction"):
		bullet_instance1.set_initial_direction(spawn_transform)
	
	# Second bullet - opposite direction
	var bullet_instance2 = bullet_scene.instantiate()
	get_tree().root.add_child(bullet_instance2)
	if bullet_instance2.has_method("set_initial_direction"):
		# Create a transform with flipped direction (180 degrees)
		var opposite_transform = spawn_transform
		opposite_transform.basis = spawn_transform.basis.rotated(Vector3.UP, PI)  # Rotate 180 degrees
		bullet_instance2.set_initial_direction(opposite_transform)
	
	# Example: Override speed if needed
	# if bullet_instance.has_variable("speed"): bullet_instance.speed = 50.0
