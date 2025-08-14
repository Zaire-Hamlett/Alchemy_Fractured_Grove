extends Node2D
class_name EnhancedChalkCircleDrawer

signal circle_completed(center: Vector2, radius: float)
signal drawing_started()
signal drawing_ended()
signal circle_progress(progress: float)

@export var line_width: float = 4.0
@export var chalk_color: Color = Color.WHITE
@export var completion_threshold: float = 0.12  # How close the end needs to be to start (12%)
@export var min_circle_radius: float = 50.0
@export var max_circle_radius: float = 300.0
@export var smoothing_factor: float = 0.15  # For line smoothing
@export var use_chalk_texture: bool = true
@export var progress_indicator_color: Color = Color(0.8, 0.8, 0.8, 0.3)  # Light gray, very transparent
@export var completion_glow_color: Color = Color.CYAN
@export var guide_circle_radius: float = 100.0
@export var auto_complete_key: String = "e"
@export var circle_cooldown_time: float = 3.0  # Seconds before circle can be redrawn

var drawing_points: Array[Vector2] = []
var is_drawing: bool = false
var start_point: Vector2
var current_line: Line2D
var smoothed_points: Array[Vector2] = []
var chalk_texture_generator: ChalkTexture

# Cooldown system
var circle_cooldown_timer: float = 0.0
var is_in_cooldown: bool = false
var circle_in_use: bool = false  # Track if circle is being used for transmutation

# Circle detection variables
var circle_center: Vector2
var circle_radius: float
var is_circle_complete: bool = false
var current_progress: float = 0.0

# E key auto-complete variables
var e_key_pressed: bool = false
var auto_complete_timer: float = 0.0
var auto_complete_delay: float = 0.1  # Time between auto-complete points
var using_mouse_input: bool = false  # Track if mouse is being used

# Visual feedback
var progress_indicator: Line2D
var completion_glow: Line2D
var chalk_dust_particles: GPUParticles2D

func _ready():
	# Create chalk texture generator
	if use_chalk_texture:
		chalk_texture_generator = ChalkTexture.new()
		chalk_texture_generator.chalk_color = chalk_color
		add_child(chalk_texture_generator)
	
	# Create the main drawing line
	current_line = Line2D.new()
	current_line.width = line_width
	current_line.default_color = chalk_color
	current_line.joint_mode = Line2D.LINE_JOINT_ROUND
	current_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	if use_chalk_texture and chalk_texture_generator:
		current_line.texture = chalk_texture_generator.get_texture()
		current_line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	
	add_child(current_line)
	
	# Create progress indicator (guide circle)
	progress_indicator = Line2D.new()
	progress_indicator.width = line_width * 0.8  # Thinner for subtlety
	progress_indicator.default_color = Color(progress_indicator_color.r, progress_indicator_color.g, progress_indicator_color.b, 0.3)  # Very transparent
	progress_indicator.joint_mode = Line2D.LINE_JOINT_ROUND
	progress_indicator.begin_cap_mode = Line2D.LINE_CAP_ROUND
	progress_indicator.end_cap_mode = Line2D.LINE_CAP_ROUND
	progress_indicator.visible = false
	add_child(progress_indicator)
	
	# Create completion glow
	completion_glow = Line2D.new()
	completion_glow.width = line_width * 2.0
	completion_glow.default_color = completion_glow_color
	completion_glow.joint_mode = Line2D.LINE_JOINT_ROUND
	completion_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	completion_glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	completion_glow.visible = false
	add_child(completion_glow)
	
	# Create chalk dust particle system
	_setup_chalk_dust_particles()
	
	# Initialize the progress indicator as a guide circle
	_create_initial_guide()

func _process(delta):
	# Handle cooldown timer
	if is_in_cooldown:
		circle_cooldown_timer += delta
		if circle_cooldown_timer >= circle_cooldown_time:
			is_in_cooldown = false
			circle_cooldown_timer = 0.0
			# Don't automatically clear the circle when cooldown ends
			# Let the user keep using it for transmutation
			print("Circle cooldown ended - circle ready for new drawing or continued use")
	
	# Handle continuous E key auto-completion (only when not using mouse)
	if e_key_pressed and is_drawing and not using_mouse_input:
		auto_complete_timer += delta
		if auto_complete_timer >= auto_complete_delay:
			auto_complete_timer = 0.0
			_auto_complete_step()

func _input(event):
	# Handle touch input
	if event is InputEventScreenTouch:
		_handle_touch_event(event)
	elif event is InputEventScreenDrag:
		_handle_drag_event(event)
	
	# Handle mouse input
	elif event is InputEventMouseButton:
		_handle_mouse_event(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	
	# Handle keyboard input for accessibility
	elif event is InputEventKey:
		_handle_keyboard_event(event)

func _handle_touch_event(event: InputEventScreenTouch):
	if event.pressed:
		_start_drawing(event.position)
	else:
		_end_drawing()

func _handle_drag_event(event: InputEventScreenDrag):
	if is_drawing:
		_add_point(event.position)

func _handle_mouse_event(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			using_mouse_input = true
			_start_drawing(to_local(event.position))
		else:
			_end_drawing()

func _handle_mouse_motion(event: InputEventMouseMotion):
	if is_drawing and using_mouse_input:
		_add_point(to_local(event.position))

func _handle_keyboard_event(event: InputEventKey):
	if event.keycode == KEY_E:
		if event.pressed:
			e_key_pressed = true
			if not is_drawing and not using_mouse_input:
				# Start drawing from the center of the guide circle
				var center_pos = progress_indicator.position
				_start_drawing(center_pos)
		else:
			e_key_pressed = false

func _setup_chalk_dust_particles():
	# Create the particle system
	chalk_dust_particles = GPUParticles2D.new()
	
	# Create particle process material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	particle_material.initial_velocity_min = 20.0
	particle_material.initial_velocity_max = 50.0
	particle_material.angular_velocity_min = -180.0
	particle_material.angular_velocity_max = 180.0
	particle_material.gravity = Vector3(0, 50.0, 0)  # Slight downward drift
	
	# Particle lifetime and emission
	particle_material.lifetime_randomness = 0.3
	
	# Scale
	particle_material.scale_min = 0.5
	particle_material.scale_max = 1.5
	
	# Color over lifetime
	particle_material.color_ramp = GradientTexture1D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(chalk_color.r, chalk_color.g, chalk_color.b, 0.8))
	gradient.add_point(0.5, Color(chalk_color.r, chalk_color.g, chalk_color.b, 0.4))
	gradient.add_point(1.0, Color(chalk_color.r, chalk_color.g, chalk_color.b, 0.0))
	particle_material.color_ramp.gradient = gradient
	
	# Apply the material
	chalk_dust_particles.process_material = particle_material
	
	# Particle appearance
	chalk_dust_particles.amount = 100
	chalk_dust_particles.lifetime = 1.0
	chalk_dust_particles.one_shot = false
	chalk_dust_particles.explosiveness = 0.1
	chalk_dust_particles.randomness = 0.3
	
	# Create a simple circle texture for particles
	var particle_texture = _create_particle_texture()
	chalk_dust_particles.texture = particle_texture
	
	add_child(chalk_dust_particles)

func _create_particle_texture() -> Texture2D:
	# Create a simple white circle texture for chalk dust particles
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw a simple circle
	for x in range(8):
		for y in range(8):
			var distance = Vector2(x - 4, y - 4).length()
			if distance <= 3:
				var alpha = 1.0 - (distance / 3.0)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(image)

func _create_initial_guide():
	# Create a complete guide circle using the progress indicator, centered on screen
	progress_indicator.visible = true
	progress_indicator.clear_points()
	
	# Get the viewport size to center the guide
	var viewport_size = get_viewport().get_visible_rect().size
	var center_pos = viewport_size / 2.0
	
	var segments = 64
	for i in range(segments + 1):
		var angle = (i * 2.0 * PI) / segments
		var point = Vector2(cos(angle), sin(angle)) * guide_circle_radius
		progress_indicator.add_point(point)
	
	# Position the guide circle at the center of the screen
	progress_indicator.position = center_pos

func clear_circle():
	"""Public function to clear the current circle"""
	_clear_circle()

func set_circle_in_use(in_use: bool):
	"""Mark the circle as being used for transmutation"""
	circle_in_use = in_use
	print("Circle marked as in use: ", in_use)

func _clear_circle():
	"""Clear all visual elements of the current circle"""
	# Don't clear if the circle is currently being used for transmutation
	if circle_in_use and is_circle_complete:
		print("Circle in use for transmutation - not clearing")
		return
	
	# Clear the main drawing line
	current_line.clear_points()
	
	# Clear the completion glow
	completion_glow.clear_points()
	completion_glow.visible = false
	
	# Clear drawing data
	drawing_points.clear()
	smoothed_points.clear()
	
	# Reset circle detection
	is_circle_complete = false
	circle_center = Vector2.ZERO
	circle_radius = 0.0
	current_progress = 0.0
	
	# Reset auto-complete variables
	auto_complete_timer = 0.0
	
	# Reset usage flag
	circle_in_use = false
	
	print("Circle cleared")

func _start_drawing(position: Vector2):
	# Check if we're in cooldown
	if is_in_cooldown:
		return  # Don't start drawing if in cooldown
	
	# If we have a complete circle, only allow new drawing if we're not currently using it
	# This prevents the circle from being cleared when interacting with it
	if is_circle_complete:
		# Check if we're actually trying to start a new drawing session
		# vs just interacting with the existing circle
		if drawing_points.size() > 0:
			print("Circle already complete and in use, ignoring new drawing start")
			return
		else:
			print("Circle complete but no points - starting fresh drawing session")
	
	# Start a fresh drawing session
	is_drawing = true
	
	# Clear the old circle completely
	_clear_circle()
	
	start_point = position
	
	# Add initial point
	drawing_points.append(position)
	smoothed_points.append(position)
	_update_line()
	
	drawing_started.emit()

func _add_point(position: Vector2):
	if not is_drawing:
		return
	
	drawing_points.append(position)
	
	# Apply smoothing
	var smoothed_point = _smooth_point(position)
	smoothed_points.append(smoothed_point)
	
	# Emit chalk dust particles
	_emit_chalk_dust(position)
	
	_update_line()
	_check_circle_progress()
	_check_circle_completion()

func _smooth_point(new_point: Vector2) -> Vector2:
	if smoothed_points.size() == 0:
		return new_point
	
	var last_point = smoothed_points[-1]
	return last_point.lerp(new_point, smoothing_factor)

func _emit_chalk_dust(position: Vector2):
	if chalk_dust_particles:
		# Position the particle emitter at the drawing point
		chalk_dust_particles.position = position
		
		# Emit a burst of particles
		chalk_dust_particles.emitting = true
		
		# Create a timer to stop emission
		var timer = get_tree().create_timer(0.05)
		timer.timeout.connect(func(): chalk_dust_particles.emitting = false)

func _update_line():
	current_line.clear_points()
	for point in smoothed_points:
		current_line.add_point(point)

func _check_circle_progress():
	if drawing_points.size() < 5:
		return
	
	# Calculate potential circle parameters
	var result = _fit_circle_to_points(drawing_points)
	if result.success:
		var center = result.center
		var radius = result.radius
		if radius >= min_circle_radius and radius <= max_circle_radius:
			# Calculate progress based on how much of the circle has been drawn
			var total_angle = _calculate_drawn_angle(drawing_points, center)
			current_progress = total_angle / (2.0 * PI)
			current_progress = clamp(current_progress, 0.0, 1.0)
			
			# Update progress indicator
			_update_progress_indicator(center, radius, current_progress)
			
			circle_progress.emit(current_progress)

func _calculate_drawn_angle(points: Array[Vector2], center: Vector2) -> float:
	if points.size() < 3:
		return 0.0
	
	var total_angle = 0.0
	for i in range(1, points.size()):
		var prev_point = points[i - 1] - center
		var curr_point = points[i] - center
		
		var angle1 = atan2(prev_point.y, prev_point.x)
		var angle2 = atan2(curr_point.y, curr_point.x)
		
		var angle_diff = angle2 - angle1
		
		# Handle angle wrapping
		if angle_diff > PI:
			angle_diff -= 2.0 * PI
		elif angle_diff < -PI:
			angle_diff += 2.0 * PI
		
		total_angle += abs(angle_diff)
	
	return total_angle

func _update_progress_indicator(center: Vector2, radius: float, progress: float):
	# Keep the guide circle as a full, transparent circle - don't show progress here
	# Progress is shown by the actual drawing line
	pass

func _auto_complete_step():
	if not is_drawing:
		return
	
	# Get the center of the guide circle
	var guide_center = progress_indicator.position
	
	# Calculate the next point on the circle
	var current_angle = 0.0
	if drawing_points.size() > 0:
		var last_point = drawing_points[-1]
		var relative_pos = last_point - guide_center
		current_angle = atan2(relative_pos.y, relative_pos.x)
	
	# Add a small angle increment
	var angle_step = 0.15  # Smaller step for smoother completion
	current_angle += angle_step
	
	# Create the next point
	var next_point = guide_center + Vector2(cos(current_angle), sin(current_angle)) * guide_circle_radius
	
	# Add the point
	drawing_points.append(next_point)
	smoothed_points.append(next_point)
	_update_line()
	
	# Check if we've completed a full circle (simpler logic)
	if drawing_points.size() > 30:
		# Check if we've gone around the circle
		var start_angle = atan2(drawing_points[0].y - guide_center.y, drawing_points[0].x - guide_center.x)
		var end_angle = atan2(drawing_points[-1].y - guide_center.y, drawing_points[-1].x - guide_center.x)
		
		# Normalize angles
		if end_angle < start_angle:
			end_angle += 2.0 * PI
		
		var angle_traveled = end_angle - start_angle
		print("Angle traveled: ", angle_traveled, " / ", 2.0 * PI, " = ", angle_traveled / (2.0 * PI))
		
		if angle_traveled >= 2.0 * PI * 0.7:  # 70% of a full circle
			print("Completing circle!")
			# Complete the circle
			_complete_circle(guide_center, guide_circle_radius)

func _complete_circle(center: Vector2, radius: float):
	# Add final points to close the circle
	var start_angle = atan2(drawing_points[0].y - center.y, drawing_points[0].x - center.x)
	var current_angle = atan2(drawing_points[-1].y - center.y, drawing_points[-1].x - center.x)
	
	# Normalize angles
	if current_angle < start_angle:
		current_angle += 2.0 * PI
	
	# Add points to close the circle
	var angle_step = 0.1
	while current_angle < start_angle + 2.0 * PI:
		current_angle += angle_step
		var point = center + Vector2(cos(current_angle), sin(current_angle)) * radius
		drawing_points.append(point)
		smoothed_points.append(point)
	
	# Update the line and complete the circle
	_update_line()
	circle_center = center
	circle_radius = radius
	is_circle_complete = true
	current_progress = 1.0
	
	# Show completion effect
	_show_completion_effect()
	circle_completed.emit(circle_center, circle_radius)
	drawing_ended.emit()
	
	# Start cooldown
	_start_cooldown()
	
	# Stop auto-completion
	e_key_pressed = false
	is_drawing = false

func _end_drawing():
	if not is_drawing:
		return
	
	is_drawing = false
	using_mouse_input = false  # Reset mouse input flag
	
	# Stop auto-completion if it was active
	e_key_pressed = false
	
	# Final circle completion check
	_check_circle_completion()
	
	if is_circle_complete:
		_show_completion_effect()
		circle_completed.emit(circle_center, circle_radius)
		_start_cooldown()
	
	drawing_ended.emit()

func _check_circle_completion():
	if drawing_points.size() < 10:
		return
	
	# Calculate potential circle parameters
	var result = _fit_circle_to_points(drawing_points)
	if result.success:
		var center = result.center
		var radius = result.radius
		# Check if the circle is reasonable
		if radius >= min_circle_radius and radius <= max_circle_radius:
			# Check if start and end points are close
			var start_dist = drawing_points[0].distance_to(drawing_points[-1])
			var circle_circumference = 2.0 * PI * radius
			var completion_ratio = start_dist / circle_circumference
			
			if completion_ratio <= completion_threshold:
				# Check if points form a reasonable circle
				var circle_score = _calculate_circle_score(drawing_points, center, radius)
				if circle_score >= 0.75:  # 75% circle quality threshold
					circle_center = center
					circle_radius = radius
					is_circle_complete = true

func _start_cooldown():
	is_in_cooldown = true
	circle_cooldown_timer = 0.0
	
	# Hide the guide circle during cooldown
	progress_indicator.visible = false
	
	# Show a visual indicator that drawing is disabled
	var cooldown_label = Label.new()
	cooldown_label.text = "Circle Complete! Wait " + str(circle_cooldown_time) + "s to draw again"
	cooldown_label.position = Vector2(get_viewport().size.x / 2 - 150, get_viewport().size.y / 2 + 100)
	cooldown_label.add_theme_font_size_override("font_size", 16)
	cooldown_label.modulate = Color.YELLOW
	add_child(cooldown_label)
	
	# Remove the label after cooldown
	var timer = get_tree().create_timer(circle_cooldown_time)
	timer.timeout.connect(func(): cooldown_label.queue_free())

func _show_completion_effect():
	completion_glow.visible = true
	completion_glow.clear_points()
	
	# Draw a complete circle for the glow effect
	var segments = 64
	for i in range(segments + 1):
		var angle = (i * 2.0 * PI) / segments
		var point = circle_center + Vector2(cos(angle), sin(angle)) * circle_radius
		completion_glow.add_point(point)
	
	# Animate the glow
	var tween = create_tween()
	tween.tween_property(completion_glow, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): completion_glow.visible = false)

func _fit_circle_to_points(points: Array[Vector2]) -> Dictionary:
	if points.size() < 3:
		return {"success": false, "center": Vector2.ZERO, "radius": 0.0}
	
	# Use least squares method to fit circle
	var sum_x = 0.0
	var sum_y = 0.0
	var sum_x2 = 0.0
	var sum_y2 = 0.0
	var sum_xy = 0.0
	var sum_x3 = 0.0
	var sum_y3 = 0.0
	var sum_xy2 = 0.0
	var sum_x2y = 0.0
	
	for point in points:
		var x = point.x
		var y = point.y
		var x2 = x * x
		var y2 = y * y
		
		sum_x += x
		sum_y += y
		sum_x2 += x2
		sum_y2 += y2
		sum_xy += x * y
		sum_x3 += x2 * x
		sum_y3 += y2 * y
		sum_xy2 += x * y2
		sum_x2y += x2 * y
	
	var n = points.size()
	var denominator = 2.0 * (sum_x2 + sum_y2 - (sum_x * sum_x + sum_y * sum_y) / n)
	
	if abs(denominator) < 0.0001:
		return {"success": false, "center": Vector2.ZERO, "radius": 0.0}
	
	var center_x = (sum_x3 + sum_xy2 - (sum_x2 * sum_x + sum_xy * sum_y) / n) / denominator
	var center_y = (sum_y3 + sum_x2y - (sum_xy * sum_x + sum_y2 * sum_y) / n) / denominator
	
	var center = Vector2(center_x, center_y)
	
	# Calculate radius
	var total_dist = 0.0
	for point in points:
		total_dist += point.distance_to(center)
	var radius = total_dist / n
	
	return {"success": true, "center": center, "radius": radius}

func _calculate_circle_score(points: Array[Vector2], center: Vector2, radius: float) -> float:
	if points.size() < 3:
		return 0.0
	
	var total_error = 0.0
	for point in points:
		var distance = point.distance_to(center)
		var error = abs(distance - radius)
		total_error += error
	
	var average_error = total_error / points.size()
	var score = 1.0 - (average_error / radius)
	return max(0.0, score)

func clear_drawing():
	drawing_points.clear()
	smoothed_points.clear()
	current_line.clear_points()
	completion_glow.clear_points()
	
	is_drawing = false
	is_circle_complete = false
	current_progress = 0.0
	
	# Restore the guide circle
	_create_initial_guide()
	completion_glow.visible = false

func get_circle_info() -> Dictionary:
	return {
		"is_complete": is_circle_complete,
		"center": circle_center,
		"radius": circle_radius,
		"progress": current_progress,
		"points_count": drawing_points.size()
	}

func set_chalk_color(color: Color):
	chalk_color = color
	current_line.default_color = color
	if chalk_texture_generator:
		chalk_texture_generator.set_chalk_color(color)
		current_line.texture = chalk_texture_generator.get_texture()
	
	# Update particle color
	if chalk_dust_particles and chalk_dust_particles.process_material:
		var material = chalk_dust_particles.process_material as ParticleProcessMaterial
		if material.color_ramp and material.color_ramp.gradient:
			var gradient = material.color_ramp.gradient
			gradient.set_color(0, Color(color.r, color.g, color.b, 0.8))
			gradient.set_color(1, Color(color.r, color.g, color.b, 0.4))
			gradient.set_color(2, Color(color.r, color.g, color.b, 0.0))

func set_guide_circle_radius(radius: float):
	guide_circle_radius = radius
	_create_initial_guide()

func set_guide_circle_position(position: Vector2):
	progress_indicator.position = position
