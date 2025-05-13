# crate_spawn.gd
extends Area3D

func _ready():
	pass

func set_size(size: Vector3):
	# Set the size of the crate
	var mesh_instance = $MeshInstance3D
	if mesh_instance and mesh_instance.mesh is BoxMesh:
		var box_mesh = mesh_instance.mesh
		box_mesh.size = size
		mesh_instance.mesh = box_mesh
	else:
		print("Mesh is not a BoxMesh or not found.")