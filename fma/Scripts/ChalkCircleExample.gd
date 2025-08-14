extends Node2D
class_name ChalkCircleExample

# Example of how to use the chalk circle system in a game
# This could be used for transmutation circles, magic spells, etc.

@export var chalk_drawer: EnhancedChalkCircleDrawer
@export var circle_effect_scene: PackedScene  # Optional effect to spawn when circle is complete

var completed_circles: Array[Dictionary] = []
var max_circles: int = 3

func _ready():
	if chalk_drawer:
		chalk_drawer.circle_completed.connect(_on_circle_completed)
		chalk_drawer.drawing_started.connect(_on_drawing_started)

func _on_circle_completed(center: Vector2, radius: float):
	print("Circle completed at: ", center, " with radius: ", radius)
	
	# Store circle information
	var circle_info = {
		"center": center,
		"radius": radius,
		"timestamp": Time.get_time_dict_from_system()
	}
	completed_circles.append(circle_info)
	
	# Check if we have enough circles for a transmutation
	if completed_circles.size() >= max_circles:
		_perform_transmutation()
	
	# Spawn visual effect
	_spawn_circle_effect(center, radius)

func _on_drawing_started():
	print("Started drawing a new circle")

func _perform_transmutation():
	print("Performing transmutation with ", completed_circles.size(), " circles!")
	
	# Example transmutation logic
	var total_radius = 0.0
	var center_point = Vector2.ZERO
	
	for circle in completed_circles:
		total_radius += circle.radius
		center_point += circle.center
	
	center_point /= completed_circles.size()
	var average_radius = total_radius / completed_circles.size()
	
	print("Transmutation center: ", center_point, " average radius: ", average_radius)
	
	# Clear circles after transmutation
	completed_circles.clear()
	if chalk_drawer:
		chalk_drawer.clear_drawing()

func _spawn_circle_effect(center: Vector2, radius: float):
	if not circle_effect_scene:
		return
	
	var effect = circle_effect_scene.instantiate()
	effect.position = center
	add_child(effect)
	
	# Scale effect based on circle radius
	if effect.has_method("set_scale"):
		var scale_factor = radius / 100.0  # Base scale on 100px radius
		effect.set_scale(Vector2(scale_factor, scale_factor))

func get_circle_count() -> int:
	return completed_circles.size()

func get_circles() -> Array[Dictionary]:
	return completed_circles

func clear_all_circles():
	completed_circles.clear()
	if chalk_drawer:
		chalk_drawer.clear_drawing()

# Example of how to check if circles form a specific pattern
func check_triangle_pattern() -> bool:
	if completed_circles.size() != 3:
		return false
	
	# Check if the three circles form roughly an equilateral triangle
	var centers = []
	for circle in completed_circles:
		centers.append(circle.center)
	
	var dist1 = centers[0].distance_to(centers[1])
	var dist2 = centers[1].distance_to(centers[2])
	var dist3 = centers[2].distance_to(centers[0])
	
	# Allow some tolerance for the triangle to be considered equilateral
	var tolerance = 0.2
	var avg_dist = (dist1 + dist2 + dist3) / 3.0
	
	return (abs(dist1 - avg_dist) / avg_dist < tolerance and
			abs(dist2 - avg_dist) / avg_dist < tolerance and
			abs(dist3 - avg_dist) / avg_dist < tolerance)

# Example of how to check if circles are in a line
func check_line_pattern() -> bool:
	if completed_circles.size() < 2:
		return false
	
	var centers = []
	for circle in completed_circles:
		centers.append(circle.center)
	
	# Check if all centers lie roughly on a line
	var first_vector = centers[1] - centers[0]
	var tolerance = 0.1
	
	for i in range(2, centers.size()):
		var current_vector = centers[i] - centers[0]
		var cross_product = first_vector.cross(current_vector)
		var distance_from_line = abs(cross_product) / first_vector.length()
		
		if distance_from_line > tolerance * first_vector.length():
			return false
	
	return true
