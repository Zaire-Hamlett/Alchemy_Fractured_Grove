extends Node2D
class_name ChalkCircleDrawer

signal circle_completed(center: Vector2, radius: float)
signal drawing_started()
signal drawing_ended()

@export var line_width: float = 3.0
@export var line_color: Color = Color.WHITE
@export var completion_threshold: float = 0.15  # How close the end needs to be to start (15%)
@export var min_circle_radius: float = 50.0
@export var max_circle_radius: float = 300.0
@export var smoothing_factor: float = 0.1  # For line smoothing

var drawing_points: Array[Vector2] = []
var is_drawing: bool = false
var start_point: Vector2
var current_line: Line2D
var smoothed_points: Array[Vector2] = []

# Circle detection variables
var circle_center: Vector2
var circle_radius: float
var is_circle_complete: bool = false

func _ready():
	# Create the line for drawing
	current_line = Line2D.new()
	current_line.width = line_width
	current_line.default_color = line_color
	current_line.joint_mode = Line2D.LINE_JOINT_ROUND
	current_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(current_line)

func _input(event):
	if event is InputEventScreenTouch:
		_handle_touch_event(event)
	elif event is InputEventScreenDrag:
		_handle_drag_event(event)

func _handle_touch_event(event: InputEventScreenTouch):
	if event.pressed:
		_start_drawing(event.position)
	else:
		_end_drawing()

func _handle_drag_event(event: InputEventScreenDrag):
	if is_drawing:
		_add_point(event.position)

func _start_drawing(position: Vector2):
	is_drawing = true
	drawing_points.clear()
	smoothed_points.clear()
	start_point = position
	
	# Add initial point
	drawing_points.append(position)
	smoothed_points.append(position)
	_update_line()
	
	# Reset circle detection
	is_circle_complete = false
	circle_center = Vector2.ZERO
	circle_radius = 0.0
	
	drawing_started.emit()

func _add_point(position: Vector2):
	if not is_drawing:
		return
	
	drawing_points.append(position)
	
	# Apply smoothing
	var smoothed_point = _smooth_point(position)
	smoothed_points.append(smoothed_point)
	
	_update_line()
	_check_circle_completion()

func _smooth_point(new_point: Vector2) -> Vector2:
	if smoothed_points.size() == 0:
		return new_point
	
	var last_point = smoothed_points[-1]
	return last_point.lerp(new_point, smoothing_factor)

func _update_line():
	current_line.clear_points()
	for point in smoothed_points:
		current_line.add_point(point)

func _end_drawing():
	if not is_drawing:
		return
	
	is_drawing = false
	
	# Final circle completion check
	_check_circle_completion()
	
	if is_circle_complete:
		circle_completed.emit(circle_center, circle_radius)
	
	drawing_ended.emit()

func _check_circle_completion():
	if drawing_points.size() < 10:
		return
	
	# Calculate potential circle parameters
	var center, radius
	if _fit_circle_to_points(drawing_points, center, radius):
		# Check if the circle is reasonable
		if radius >= min_circle_radius and radius <= max_circle_radius:
			# Check if start and end points are close
			var start_dist = drawing_points[0].distance_to(drawing_points[-1])
			var circle_circumference = 2.0 * PI * radius
			var completion_ratio = start_dist / circle_circumference
			
			if completion_ratio <= completion_threshold:
				# Check if points form a reasonable circle
				var circle_score = _calculate_circle_score(drawing_points, center, radius)
				if circle_score >= 0.7:  # 70% circle quality threshold
					circle_center = center
					circle_radius = radius
					is_circle_complete = true

func _fit_circle_to_points(points: Array[Vector2], center: Vector2, radius: float) -> bool:
	if points.size() < 3:
		return false
	
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
		return false
	
	var center_x = (sum_x3 + sum_xy2 - (sum_x2 * sum_x + sum_xy * sum_y) / n) / denominator
	var center_y = (sum_y3 + sum_x2y - (sum_xy * sum_x + sum_y2 * sum_y) / n) / denominator
	
	center = Vector2(center_x, center_y)
	
	# Calculate radius
	var total_dist = 0.0
	for point in points:
		total_dist += point.distance_to(center)
	radius = total_dist / n
	
	return true

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
	is_drawing = false
	is_circle_complete = false

func get_circle_info() -> Dictionary:
	return {
		"is_complete": is_circle_complete,
		"center": circle_center,
		"radius": circle_radius,
		"points_count": drawing_points.size()
	}
