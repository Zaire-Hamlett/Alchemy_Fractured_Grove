extends Control

@onready var chalk_drawer: EnhancedChalkCircleDrawer = $Canvas/ChalkCircleDrawer
@onready var info_label: Label = $UI/BottomPanel/InfoLabel
@onready var clear_button: Button = $UI/BottomPanel/ClearButton
@onready var color_button: Button = $UI/BottomPanel/ColorButton
@onready var accessibility_label: Label = $UI/BottomPanel/AccessibilityLabel

var chalk_colors: Array[Color] = [
	Color(0.9, 0.9, 0.8, 1),  # White chalk
	Color(0.8, 0.6, 0.4, 1),  # Brown chalk
	Color(0.6, 0.8, 0.6, 1),  # Green chalk
	Color(0.8, 0.6, 0.8, 1),  # Purple chalk
	Color(0.6, 0.6, 0.8, 1),  # Blue chalk
	Color(0.8, 0.8, 0.6, 1),  # Yellow chalk
]
var current_color_index: int = 0

func _ready():
	# Connect signals
	chalk_drawer.circle_completed.connect(_on_circle_completed)
	chalk_drawer.drawing_started.connect(_on_drawing_started)
	chalk_drawer.drawing_ended.connect(_on_drawing_ended)
	chalk_drawer.circle_progress.connect(_on_circle_progress)
	
	# Connect button signals
	clear_button.pressed.connect(_on_clear_button_pressed)
	color_button.pressed.connect(_on_color_button_pressed)
	
	# Set initial color
	chalk_drawer.set_chalk_color(chalk_colors[current_color_index])

func _on_circle_completed(center: Vector2, radius: float):
	var info = chalk_drawer.get_circle_info()
	info_label.text = "Transmutation Circle Complete!\nCenter: (%.1f, %.1f)\nRadius: %.1f\nPoints: %d\nReady for alchemy!" % [
		center.x, center.y, radius, info.points_count
	]
	
	# Add some visual feedback
	var tween = create_tween()
	tween.tween_property(info_label, "modulate", Color.YELLOW, 0.2)
	tween.tween_property(info_label, "modulate", Color.WHITE, 0.2)

func _on_drawing_started():
	info_label.text = "Transmutation circle drawing started...\nDraw a complete circle!\nPress 'E' to auto-complete if needed."

func _on_drawing_ended():
	var info = chalk_drawer.get_circle_info()
	if not info.is_complete:
		info_label.text = "Drawing ended.\nTry drawing a more complete transmutation circle!"

func _on_circle_progress(progress: float):
	var info = chalk_drawer.get_circle_info()
	if info.is_complete:
		return
	
	var progress_text = "Transmutation Progress: %.1f%%" % (progress * 100)
	info_label.text = progress_text + "\nKeep drawing to complete the transmutation circle!"

func _on_clear_button_pressed():
	chalk_drawer.clear_drawing()
	info_label.text = "Canvas cleared.\nDraw a transmutation circle to begin..."

func _on_color_button_pressed():
	current_color_index = (current_color_index + 1) % chalk_colors.size()
	chalk_drawer.set_chalk_color(chalk_colors[current_color_index])
	
	# Show color change feedback
	var color_name = _get_color_name(chalk_colors[current_color_index])
	info_label.text = "Changed to " + color_name + " chalk!"

func _get_color_name(color: Color) -> String:
	if color == chalk_colors[0]:
		return "White"
	elif color == chalk_colors[1]:
		return "Brown"
	elif color == chalk_colors[2]:
		return "Green"
	elif color == chalk_colors[3]:
		return "Purple"
	elif color == chalk_colors[4]:
		return "Blue"
	elif color == chalk_colors[5]:
		return "Yellow"
	else:
		return "Custom"
