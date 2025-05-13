# LaserChargeIndicator.gd
extends Control

# Make properties editable in Inspector and code
@export var ellipse_outer_width: float = 100.0
@export var ellipse_outer_height: float = 60.0
@export var ellipse_thickness: float = 3.0

@export var rect_width: float = 80.0
@export var rect_height: float = 80.0
@export var rect_thickness: float = 2.0

@export var shape_color: Color = Color.CYAN

var is_charging: bool = false
var charge_timer: SceneTreeTimer = null

# Function to make queue_redraw() happen when @export vars change
func _set_property_redraw(value, property_name: String = ""):
	# This is boilerplate to update the property and trigger a redraw
	# You need to repeat this for each property you want to auto-redraw
	match property_name:
		"ellipse_outer_width": ellipse_outer_width = value
		"ellipse_outer_height": ellipse_outer_height = value
		"ellipse_thickness": ellipse_thickness = value
		"rect_width": rect_width = value
		"rect_height": rect_height = value
		"rect_thickness": rect_thickness = value
		"shape_color": shape_color = value

	if is_processing(): # Only redraw if node is active
		queue_redraw()


# Override the _draw function to draw your shapes
func _draw():
	if not is_charging:
		return # Don't draw if not charging

	var center = size / 2.0 # Center of this Control node

	# Draw Hollow Rectangle
	var rect_size = Vector2(rect_width, rect_height)
	var rect_pos = center - (rect_size / 2.0)
	draw_rect(Rect2(rect_pos, rect_size), shape_color, false, rect_thickness)

	# Draw Hollow Ellipse (Approximation using draw_polyline)
	# draw_ellipse is not a built-in function. We draw a polygon.
	var points = PackedVector2Array()
	var segments = 64 # More segments = smoother ellipse
	for i in range(segments + 1):
		var angle = TAU * float(i) / segments
		# Outer point
		var outer_x = center.x + (ellipse_outer_width / 2.0) * cos(angle)
		var outer_y = center.y + (ellipse_outer_height / 2.0) * sin(angle)
		points.append(Vector2(outer_x, outer_y))

		# Inner point (approximate thickness) - More complex for true thickness
		# This simple version just draws the outer line
		# For actual thickness, you might draw two polylines or use shaders.

	# Draw the polyline connecting the points for the outer ellipse shape
	# Note: draw_polyline doesn't have thickness itself easily.
	# We can draw multiple slightly offset lines or use draw_primitive
	# For simplicity here, let's just draw the line:
	# draw_polyline(points, shape_color, ellipse_thickness) # This might look chunky

	# Alternative: Draw arcs (simpler for circular, harder for ellipse)
	# draw_arc(center, ellipse_outer_width / 2.0, 0, TAU, 64, shape_color, ellipse_thickness)
	# ^^ This draws a CIRCLE, not ellipse unless width == height.

	# --- Let's focus on the draw_rect as it's directly supported ---
	# --- For the ellipse, drawing a polyline outline is the basic way ---
	if points.size() > 1 :
		draw_polyline(points, shape_color, 2.0) # Draw a basic outline, thickness might vary


# Call this function to start the visual effect
func start_charge_visuals(duration: float = 1.0):
	print("Starting laser charge visual")
	is_charging = true
	visible = true
	queue_redraw() # Trigger _draw()

	# Stop after duration
	if charge_timer != null and charge_timer.is_connected("timeout", stop_charge_visuals):
		charge_timer.stop() # Stop previous timer if any
	# Create timer dynamically
	charge_timer = get_tree().create_timer(duration, false) # false = not paused
	charge_timer.timeout.connect(stop_charge_visuals)


# Call this function to stop the visual effect
func stop_charge_visuals():
	print("Stopping laser charge visual")
	is_charging = false
	visible = false
	if charge_timer != null:
		# Disconnect to avoid issues if the timer node is reused by the tree
		if charge_timer.is_connected("timeout", stop_charge_visuals):
			charge_timer.timeout.disconnect(stop_charge_visuals)
		# No need to free SceneTreeTimer, it cleans itself up
		charge_timer = null
	queue_redraw() # Clear the drawing if needed (though hiding is usually enough)