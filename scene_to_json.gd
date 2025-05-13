extends Node3D

var json_generated = false

func _ready():
	# Only run in the editor when triggered
	#if Engine.is_editor_hint():
		#generate_json()\
	pass

#func _input(event):
	#if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE and not json_generated:
		#print("JSON")
		#generate_json()
		#json_generated = true

func generate_json():
	var player = get_parent()  # Access the Player node
	var json_data = {}
	traverse_node(player, json_data, true)
	var json_string = JSON.stringify(json_data, "  ")  # Pretty-print with 2 spaces
	save_to_file(json_string, "res://player_data.json")
	print("JSON file generated at res://player_data.json")

#func traverse_node(node, is_main_tree = true):
	#print("node name ", node.name)
	#var data = {
		#"name": node.name,
		#"type": node.get_class(),
		#"properties": get_node_properties(node),
		#"script": get_script_content(node),
		#"children": []
	#}
#
	## Handle instantiated scenes (e.g., weapon_visual.tscn)
	#if is_main_tree and node != get_tree().current_scene and node.get("scene_file_path"):  # Check if this node instances a scene
		#var scene_path = node.get("scene_file_path")
		#if ResourceLoader.exists(scene_path):
			#var packed_scene = load(scene_path) as PackedScene
			#if packed_scene:
				#var instanced = packed_scene.instantiate()
				#data["instanced_scene"] = traverse_node(instanced, false)
				#instanced.queue_free()
#
	## Recursively process children
	#for child in node.get_children():
		#data["children"].append(traverse_node(child, is_main_tree))
#
	#return data
	
func traverse_node(node, parent_dict, is_main_tree = true):
	var node_dict = {
		"name": node.name,
		"type": node.get_class()
	}

	# If this node instances a scene, include its path
	if node.scene_file_path:
		node_dict["scene_file_path"] = node.scene_file_path

	# Include the script if attached
	if node.script:
		node_dict["script"] = get_script_text(node.script)

	# Add node properties
	node_dict["properties"] = get_node_properties(node)

	# Process children
	var children = []
	for child in node.get_children():
		var child_dict = {}
		traverse_node(child, child_dict)
		children.append(child_dict)
	if children.size() > 0:
		node_dict["children"] = children

	# Assign this node's data to the parent dictionary
	for key in node_dict:
		parent_dict[key] = node_dict[key]

func get_script_text(script):
	var source = script.source_code
	return source if source else ""

func get_node_properties(node):
	var properties = {}
	# Get all properties from the Inspector
	for prop in node.get_property_list():
		var name = prop["name"]
		# Filter out built-in properties if desired, or include all F
		# Only include properties that are stored or editable
		if prop["usage"] & PROPERTY_USAGE_EDITOR or prop["usage"] & PROPERTY_USAGE_STORAGE:
			var value = node.get(name)
			if value is Resource:
				properties[name] = serialize_resource(value)
			elif value is Array:
				properties[name] = serialize_array(value)
			else:
				properties[name] = value
	return properties

func serialize_resource(resource):
	if resource is WeaponResource:
		return {
			"weapon_name": resource.weapon_name,
			"display_text": resource.display_text,
			"weapon_visual_scene": resource.weapon_visual_scene.resource_path if resource.weapon_visual_scene else ""
			# Add more properties like ammo type, max ammo, etc., when you expand WeaponResource
		}
	# Fallback for other resources
	return resource.resource_path if resource else ""

func serialize_array(array):
	var serialized = []
	for item in array:
		if item is Resource:
			serialized.append(serialize_resource(item))
		else:
			serialized.append(item)
	return serialized

func get_script_content(node):
	if node.get_script():
		var script = node.get_script()
		var path = script.resource_path
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			return file.get_as_text()
	return ""

func save_to_file(content, path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
