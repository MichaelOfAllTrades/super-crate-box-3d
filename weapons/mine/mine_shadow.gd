# MineShadow.gd
extends Node3D

# References to child nodes (assigned in _ready)
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	print("MineShadow: Ready")
	_update_dimensions()

func _update_dimensions() -> void:
	if mesh_instance and mesh_instance.mesh is CylinderMesh:
		var new_size = Vector3(GameConfig.mine_width, GameConfig.mine_height, GameConfig.mine_width)
		print("MineShadow: Updating dimensions to: ", new_size)
		mesh_instance.mesh.top_radius = GameConfig.mine_width
		mesh_instance.mesh.bottom_radius = GameConfig.mine_width
		mesh_instance.mesh.height = GameConfig.mine_height
