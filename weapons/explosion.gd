extends Area3D

@export var start_radius: float = 0.1
@export var max_radius: float = 120.0
@export var growth_duration: float = 0.5
@export var damage: int = 100

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var current_radius: float = 0.0
var elapsed_time: float = 0.0

func _ready():
	current_radius = start_radius
	_update_visuals()
	# Monitor bodies entering IMMEDIATELY upon create too
	_check_overlaps()
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	elapsed_time += delta
	if elapsed_time >= growth_duration:
		current_radius = max_radius
		_update_visuals()
		# After reaching max size, maybe linger for a moment then disappear
		await get_tree().create_timer(0.1).timeout
		queue_free()
	else:
		# Linear growth for simplicity
		var progress = elapsed_time / growth_duration
		current_radius = lerp(start_radius, max_radius, progress)
		_update_visuals()
		# Continuously check overlaps during growth
		_check_overlaps()

func _update_visuals():
	if mesh_instance and mesh_instance.mesh is SphereMesh:
		mesh_instance.mesh.radius = current_radius
		mesh_instance.mesh.height = current_radius * 2.0
	if collision_shape and collision_shape.shape is SphereShape3D:
		collision_shape.shape.radius = current_radius
	
	# Scale the Area3D itself - might be redundant if shape updates work
	# self.scale = Vector.3.ONE * (current_radius / initial_shape_radius_if_known)

func _check_overlaps():
	# Apply damage ONCE per enemy
	for body in get_overlapping_bodies():
		if body.has_method("take_damage") and not body.has_meta("exploding_hit"):
			body.take_damage(damage)
			body.set_meta("exploded_hit", true) # Maek as hit by this explosion
			# Clean up meta after a frame? Or rely on enemy deletion?
	
func _on_body_entered(body):
	# Also check when bodies enter dynamically
	if body.has_method("take_damage") and not body.has_meta("exploded_hit"):
		body.take_damage(damage)
		body.set_meta("exploded_hit", true)
	
func _exit_tree():
	# Clean up meta tag from bodies potentially hit when explosion disappears
	# This is complex - maybe better to handle damage resistance/timing on enemy side
	pass
