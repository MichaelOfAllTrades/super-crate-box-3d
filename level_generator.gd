extends Node3D

@export var wall_prefab : PackedScene
var wall_data_list : Array = []
var walls : Array = []

func _ready():
	initialize_wall_data()
	generate_level()
	
func initialize_wall_data():
	var zdiff = 0 # Or whatever value you need
	wall_data_list.append({
		"name": "reference",
		"position": Vector3(0, 0, 0),
		"size": Vector3(20, 20, 20)
	})
	print("created reference")
	
	wall_data_list.append({
		"name": "back wall",
		"position": Vector3(0, (640 / 2), (960 / 2)),
		"size": Vector3(20, 640, 960)
	})
	
	wall_data_list.append({
		"name": "left most wall",
		"position": Vector3(30, (640 - 0) - (560 / 2), (40 / 2) + zdiff),
		"size": Vector3(60, 560, 40)
	})
	
	wall_data_list.append({
		"name": "left roof",
		"position": Vector3(30, (640 - 0) - (40 / 2), (400 / 2) + zdiff),
		"size": Vector3(60, 40, 400)
	})
	
	wall_data_list.append({
		"name": "left base bottom",
		"position": Vector3(30, (640 - 600) - (40 / 2), (440 / 2) + zdiff),
		"size": Vector3(60, 40, 440)
	})
	
	wall_data_list.append({
		"name": "left base top",
		"position": Vector3(30, (640 - 560) - (40 / 2), (240 / 2) + zdiff),
		"size": Vector3(60, 40, 240)
	})
	
	wall_data_list.append({
		"name": "left middle",
		"position": Vector3(30, (640 - 293) - (40 / 2), (240 / 2) + zdiff),
		"size": Vector3(60, 40, 240)
	})
	
	wall_data_list.append({
		"name": "upper platform",
		"position": Vector3(30, (640 - 189) - (40 / 2), 240 + (478 / 2) + zdiff),
		"size": Vector3(60, 40, 478)
	})
	
	wall_data_list.append({
		"name": "lower platform",
		"position": Vector3(30, (640 - 440) - (40 / 2), 240 + (478 / 2) + zdiff),
		"size": Vector3(60, 40, 478)
	})
	
	wall_data_list.append({
		"name": "right most wall",
		"position": Vector3(30, (640 - 0) - (560 / 2), 920 + (40 / 2) + zdiff),
		"size": Vector3(60, 560, 40)
	})
	
	wall_data_list.append({
		"name": "right roof",
		"position": Vector3(30, (640 - 0) - (40 / 2), 520 + (400 / 2) + zdiff),
		"size": Vector3(60, 40, 400)
	})
	
	wall_data_list.append({
		"name": "right base bottom",
		"position": Vector3(30, (640 - 600) - (40 / 2), 520 + (440 / 2) + zdiff),
		"size": Vector3(60, 40, 440)
	})
	
	wall_data_list.append({
		"name": "right base top",
		"position": Vector3(30, (640 - 560) - (40 / 2), 720 + (240 / 2) + zdiff),
		"size": Vector3(60, 40, 240)
	})
	
	wall_data_list.append({
		"name": "right middle",
		"position": Vector3(30, (640 - 293) - (40 / 2), 720 + (240 / 2) + zdiff),
		"size": Vector3(60, 40, 240)
	})

func generate_level():
	var units_per_pixel = 0.1 # Adjust as needed
	for wall_data in wall_data_list:
		var wall = wall_prefab.instantiate()
		add_child(wall)

		wall.name = wall_data["name"]
		wall.position = wall_data["position"] * units_per_pixel
		wall.scale = wall_data["size"] * units_per_pixel
		
		if wall.has_node("MeshInstance3D"):
			var mesh_instance = wall.get_node("MeshInstance3D")
			#Check if the MeshInstance has a material override
			if mesh_instance.material_override:
				mesh_instance.material_override.albedo_color = Color(0, 0.8, 0.4) # Color in Godot is normalized (0-1)

			#Otherwise we create the material override to change the color
			else:
				var material = StandardMaterial3D.new()
				material.albedo_color = Color(0, 0.8, 0.4)
				mesh_instance.material_override = material


		# Add the wall to the scene (important!)  Parent to the appropriate node
		add_child(wall)
