extends Node2D
class_name ElementDragSystem

signal element_dropped(element: TransmutationSystem.Element, position: Vector2)

@export var element_size: Vector2 = Vector2(64, 64)
@export var drag_offset: Vector2 = Vector2(32, 32)

var element_buttons: Array[Button] = []
var dragged_element: TransmutationSystem.Element = null
var drag_sprite: Sprite2D = null
var is_dragging: bool = false
var transmutation_system: TransmutationSystem
var chalk_circle_drawer: EnhancedChalkCircleDrawer

func _ready():
	# Don't create a new transmutation system - use the one passed from GameManager
	# transmutation_system = TransmutationSystem.new()
	# add_child(transmutation_system)
	
	# Connect to circle completion
	if chalk_circle_drawer:
		chalk_circle_drawer.circle_completed.connect(_on_circle_completed)
	
	_setup_element_panel()

func _setup_element_panel():
	# Create element panel
	var element_panel = Panel.new()
	element_panel.size = Vector2(400, 200)
	element_panel.position = Vector2(10, 10)
	element_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(element_panel)
	
	# Create title
	var title = Label.new()
	title.text = "Elements"
	title.position = Vector2(10, 10)
	title.add_theme_font_size_override("font_size", 18)
	element_panel.add_child(title)
	
	# Create element buttons
	var element_types = [
		TransmutationSystem.ElementType.FIRE,
		TransmutationSystem.ElementType.WATER,
		TransmutationSystem.ElementType.EARTH,
		TransmutationSystem.ElementType.AIR,
		TransmutationSystem.ElementType.METAL,
		TransmutationSystem.ElementType.ORGANIC,
		TransmutationSystem.ElementType.LIGHT,
		TransmutationSystem.ElementType.DARK,
		TransmutationSystem.ElementType.LIFE,
		TransmutationSystem.ElementType.DEATH,
		TransmutationSystem.ElementType.VOID,
		TransmutationSystem.ElementType.COPPER,
		TransmutationSystem.ElementType.TIN
	]
	
	var button_size = Vector2(50, 50)
	var buttons_per_row = 7  # Increased to accommodate more elements
	var start_pos = Vector2(10, 40)
	
	for i in range(element_types.size()):
		var element = transmutation_system.get_element_by_type(element_types[i])
		var button = _create_element_button(element, button_size)
		
		var row = i / buttons_per_row
		var col = i % buttons_per_row
		button.position = start_pos + Vector2(col * (button_size.x + 5), row * (button_size.y + 5))
		
		element_panel.add_child(button)
		element_buttons.append(button)

func _create_element_button(element: TransmutationSystem.Element, size: Vector2) -> Button:
	var button = Button.new()
	button.size = size
	button.tooltip_text = element.name + ": " + element.description
	
	# Create element texture
	var texture = _create_element_button_texture(element.color)
	button.icon = texture
	
	# Connect button press
	button.button_down.connect(func(): _start_drag(element))
	
	# Set mouse filter to stop propagation when over button
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	return button

func _create_element_button_texture(color: Color) -> Texture2D:
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw element symbol
	for x in range(32):
		for y in range(32):
			var distance = Vector2(x - 16, y - 16).length()
			if distance <= 14:
				var alpha = 1.0 - (distance / 14.0)
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	return ImageTexture.create_from_image(image)

func _start_drag(element: TransmutationSystem.Element):
	dragged_element = element
	is_dragging = true
	
	# Create drag sprite
	drag_sprite = Sprite2D.new()
	drag_sprite.texture = _create_element_button_texture(element.color)
	drag_sprite.modulate = Color(1, 1, 1, 0.8)
	drag_sprite.z_index = 1000
	get_tree().current_scene.add_child(drag_sprite)
	
	# Set initial position
	var mouse_pos = get_global_mouse_position()
	drag_sprite.position = mouse_pos - drag_offset

func _unhandled_input(event):
	if not is_dragging or not drag_sprite:
		return
	
	if event is InputEventMouseMotion:
		drag_sprite.position = event.position - drag_offset
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_end_drag(event.position)



func _end_drag(position: Vector2):
	print("Ending drag for element: ", dragged_element.name if dragged_element else "none")
	
	if not is_dragging or not dragged_element:
		return
	
	# Check if dropped on a completed circle
	if chalk_circle_drawer and chalk_circle_drawer.get_circle_info()["is_complete"]:
		var circle_info = chalk_circle_drawer.get_circle_info()
		var circle_center = circle_info["center"]
		print("Circle is complete. Center: ", circle_center, ", Radius: ", circle_info["radius"])
		
		# Check if drop position is near the circle
		var distance = position.distance_to(circle_center)
		print("Drop distance from circle: ", distance, " (max: ", circle_info["radius"] + 50, ")")
		
		if distance <= circle_info["radius"] + 50:
			print("Dropped on circle! Adding element to transmutation...")
			# Add element to transmutation
			var success = transmutation_system.add_element_to_circle(dragged_element, circle_center)
			print("Element addition result: ", success)
			if success:
				element_dropped.emit(dragged_element, position)
		else:
			print("Dropped too far from circle")
	else:
		print("Circle is not complete or chalk_circle_drawer is null")
	
	# Clean up drag
	is_dragging = false
	dragged_element = null
	if drag_sprite:
		drag_sprite.queue_free()
		drag_sprite = null

func _on_circle_completed(center: Vector2, radius: float):
	# Enable element dragging when circle is completed
	modulate = Color.WHITE

func set_chalk_circle_drawer(drawer: EnhancedChalkCircleDrawer):
	chalk_circle_drawer = drawer

func set_transmutation_system(system: TransmutationSystem):
	transmutation_system = system

func get_transmutation_system() -> TransmutationSystem:
	return transmutation_system
