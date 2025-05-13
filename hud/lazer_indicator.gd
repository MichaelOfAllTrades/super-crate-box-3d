# lazer_indicator.gd
extends Control

# Export variables to control the relative sizes from the Inspector
# Value represents the fraction of the parent container's dimension
@export var small_circle_diameter_factor : float = 0.05 # e.g., 5% of the smaller parent dimension
@export var oval_width_factor : float = 0.7 # e.g., 70% of the parent width
@export var oval_height_factor : float = 0.3 # e.g., 30% of the parent height

# Colors (optional, can be hardcoded too)
@export var small_circle_color : Color = Color(1, 0, 0) # Red
@export var oval_color : Color = Color(0, 1, 0) # Green


func _ready() -> void:
	visible = false # Start invisible, can be toggled on/off as needed
	GameEvents.lazer_charging_started.connect(_on_lazer_charging_started)
	GameEvents.lazer_charging_stoppped.connect(_on_lazer_charging_stopped)


func _on_lazer_charging_started() -> void:
	# print("lazer charging started")
	visible = true
	queue_redraw() # Request a redraw to update the visual state

func _on_lazer_charging_stopped() -> void:
	# print("lazer charging stopped")
	visible = false
	queue_redraw() # Request a redraw to update the visual state

func _draw() -> void:
	# Ensure we have a valid parent to get size from
	var parent = get_parent()
	if not is_instance_valid(parent):
		return # Cannot draw without parent size

	# Get the size of the parent container (CenterLazerIndicatorContainer)
	# This container fills the screen, so this is effectively the screen size.
	var parent_size : Vector2 = parent.get_rect().size

	# Calculate the center point *within this Control node's local coordinates*
	# Since the parent is a CenterContainer, this Control node itself might be
	# smaller than the parent, but _draw() works in local coordinates.
	# We want to draw relative to the center of *this* control.
	var control_center : Vector2 = get_rect().size / 2.0

	# --- Draw the Small Circle ---
	# Calculate diameter based on the *smaller* dimension of the parent container
	var small_circle_diameter : float = min(parent_size.x, parent_size.y) * small_circle_diameter_factor
	var small_circle_radius : float = small_circle_diameter / 2.0

	# Draw the circle centered within this Control node
	draw_circle(control_center, small_circle_radius, small_circle_color)

	# --- Draw the Large Oval ---
	# We'll draw a base circle and scale it non-uniformly using draw_set_transform.

	# 1. Define the target dimensions of the oval based on parent size
	var target_oval_width : float = parent_size.x * oval_width_factor
	var target_oval_height : float = parent_size.y * oval_height_factor

	# 2. Define a base radius for the circle we are going to scale.
	#    Let's make the base circle have a diameter equal to the smaller
	#    target dimension of the oval, so scaling is mostly expansion.
	#    Alternatively, use a fixed value like 1.0 if preferred.
	var base_oval_radius : float = min(target_oval_width, target_oval_height) / 2.0
	# Avoid division by zero if factors are zero
	if base_oval_radius <= 0.001:
		base_oval_radius = 1.0 # Use a fallback radius

	# 3. Calculate the necessary scale factors
	#    scale_x = target_width / (2 * base_radius)
	#    scale_y = target_height / (2 * base_radius)
	var scale_x : float = target_oval_width / (2.0 * base_oval_radius)
	var scale_y : float = target_oval_height / (2.0 * base_oval_radius)
	var scale_vector : Vector2 = Vector2(scale_x, scale_y)

	# 4. Apply the transformation
	#    We want to scale *around* the center of our control node.
	#    draw_set_transform applies transformations relative to the provided origin.
	var current_transform = get_canvas_transform() # Store current transform if needed later
	draw_set_transform(control_center, 0.0, scale_vector) # Position, Rotation (rad), Scale

	# 5. Draw the base circle (arc) at the transformed origin (0,0)
	#    Since we set the transform origin to 'control_center' and applied scale,
	#    drawing at Vector2.ZERO locally will place the scaled shape correctly.
	#    Use draw_arc for a potentially smoother circle than draw_circle.
	#    Use a reasonable number of points (e.g., 64) for smoothness.
	#    IMPORTANT: The 'width' parameter in draw_arc is line thickness when antialiased=true.
	#               To draw a filled-like oval outline, keep width small or use draw_primitive/polygon.
	#               For a simple outline, use draw_arc as below. Set antialiased=true for better looks.
	draw_arc(Vector2.ZERO, base_oval_radius, 0, TAU, 64, oval_color, 2.0, true) # Draw with thickness 2, antialiased

	# 6. Reset the transform to default to avoid affecting subsequent draws (if any)
	#    Reset using the stored transform or default values
	#    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	#    Or restore the original one precisely:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# pass # No longer needed

# Optional: Ensure disconnection if the node is removed
func _exit_tree() -> void:
	GameEvents.lazer_charging_started.connect(_on_lazer_charging_started)
	GameEvents.lazer_charging_stoppped.connect(_on_lazer_charging_stopped)
