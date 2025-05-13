# RevolverWeapon.gd
@tool # Allows properties to update in editor potentially
class_name RevolverWeapon
extends BaseWeaponLogic

@export var bullet_scene: PackedScene # Assign pistol_bullet.tscn

# Override the base fire method
func fire():
	if not bullet_scene:
		printerr("RevolverWeapon: Bullet scene not assigned!")
		return
	
	print("Revolver firing!")
	var spawn_transform = get_muzzle_global_transform()
	
	var bullet_instance = bullet_scene.instantiate()

	# Modify the bullet's scale before adding it to the scene
	bullet_instance.scale = Vector3(2.5, 2.5, 2.5)
	print("revolver bullet size: ", bullet_instance.scale)

	# Add to main scene tree (get_tree().root is simple way)
	get_tree().root.add_child(bullet_instance) 

	# Set bullet properties (assuming bullet script has these methods/vars)
	if bullet_instance.has_method("set_initial_direction"):
		bullet_instance.set_initial_direction(spawn_transform)
	# Example: Override speed if needed
	# if bullet_instance.has_variable("speed"): bullet_instance.speed = 50.0