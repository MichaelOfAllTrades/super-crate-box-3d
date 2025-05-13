# LaserSegment.gd
# extends Area3D
extends Area3D
@export var decay_rate: float = 10.0 # Units of width per second
@export var min_width: float = 0.01
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	var current_scale = scale
	current_scale.x -= decay_rate * delta
	current_scale.y -= decay_rate * delta # Assuming X and Z are width/depth

	if current_scale.x <= min_width or current_scale.z <= min_width:
		queue_free()
	else:
		scale = current_scale

func _on_body_entered(body):
	print("LaserSegment hit: ", body.name)
	if body.has_method("take_damage"):
		body.take_damage(100)