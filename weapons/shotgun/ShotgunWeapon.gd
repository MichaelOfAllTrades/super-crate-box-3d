# ShotgunWeapon.gd
@tool # Allows properties to update in editor potentially
class_name ShotgunWeapon
extends BaseWeaponLogic

@export var bullet_scene: PackedScene # Assign pistol_bullet.tscn

@export_range(0.0, 10.0, 0.1) var spread_angle_degrees: float = 3.0

var java_base_speeds: Array = [35, 33, 20, 20, 18, 17]

var speed_variance_range: float = 5.0

@export var speed_scaling_factor: float = 50.0

# Override the base fire method
func fire():
	if not bullet_scene:
		printerr("ShotgunWeapon: Bullet scene not assigned!")
		return
	
	print("Shotgun firing!")
	var spawn_transform = get_muzzle_global_transform()

	for i in range(6):
		var bullet_instance = bullet_scene.instantiate()
		var pellet_transform = spawn_transform
		var rand_pitch = deg_to_rad(randf_range(-spread_angle_degrees, spread_angle_degrees))
		var rand_yaw = deg_to_rad(randf_range(-spread_angle_degrees, spread_angle_degrees))

		pellet_transform.basis = pellet_transform.basis.rotated(pellet_transform.basis.x.normalized(), rand_pitch)
		pellet_transform.basis = pellet_transform.basis.rotated(pellet_transform.basis.y.normalized(), rand_yaw)

		get_tree().root.add_child(bullet_instance)

		if bullet_instance.has_method("set_initial_direction"):
			bullet_instance.set_initial_direction(pellet_transform)
		else:
			printerr("ShotgunWeapon: Bullet scene does not have set_initial_direction method!")
		
		var base_java_speed = java_base_speeds[i] # Get base speed for this specific pellet index (0-5)
		var random_variance = randf_range(0, speed_variance_range) # Get random value between 0.0 and 5.0
		var initial_speed = (base_java_speed + random_variance) * speed_scaling_factor # Scale Java speed to 3D scale

		if bullet_instance.has_method("set_initial_speed"):
			bullet_instance.set_initial_speed(initial_speed)
			# print("Pellet ", i, " initial speed: ", initial_speed) # Debugging speed distribution
		else:
			printerr("ShotgunWeapon: Bullet scene does not have set_initial_speed method!")