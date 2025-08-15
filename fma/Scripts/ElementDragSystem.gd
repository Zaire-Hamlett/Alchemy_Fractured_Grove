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

# Performance optimization: texture caching
var texture_cache: Dictionary = {}
var last_mouse_position: Vector2 = Vector2.ZERO
var drag_update_threshold: float = 5.0  # Minimum distance to update drag position

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
	
	# Create element buttons (optimized)
	_create_element_buttons_optimized(element_panel)

func _create_element_buttons_optimized(parent: Panel):
	"""Optimized element button creation with caching"""
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
		var button = _create_element_button_cached(element, button_size)
		
		var row = i / buttons_per_row
		var col = i % buttons_per_row
		button.position = start_pos + Vector2(col * (button_size.x + 5), row * (button_size.y + 5))
		
		parent.add_child(button)
		element_buttons.append(button)

func _create_element_button_cached(element: TransmutationSystem.Element, size: Vector2) -> Button:
	"""Optimized button creation with texture caching"""
	var button = Button.new()
	button.size = size
	button.tooltip_text = element.name + ": " + element.description
	
	# Use cached texture if available
	var cache_key = str(element.type) + "_" + str(size)
	if cache_key not in texture_cache:
		texture_cache[cache_key] = _create_element_button_texture(element.color)
	
	button.icon = texture_cache[cache_key]
	
	# Connect button press
	button.button_down.connect(func(): _start_drag(element))
	
	# Set mouse filter to stop propagation when over button
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	return button

func _create_element_button_texture(color: Color) -> Texture2D:
	"""Optimized texture creation - smaller size for better performance"""
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)  # Reduced from 32x32
	image.fill(Color.TRANSPARENT)
	
	# Draw element symbol (optimized circle drawing)
	var center = Vector2(12, 12)
	var radius = 10
	
	for x in range(24):
		for y in range(24):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				var alpha = 1.0 - (distance / radius) * 0.3
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	return ImageTexture.create_from_image(image)

func _start_drag(element: TransmutationSystem.Element):
	"""Optimized drag start with cached sprite creation"""
	if is_dragging:
		return  # Already dragging something
	
	dragged_element = element
	is_dragging = true
	
	# Create drag sprite (use cached texture)
	drag_sprite = Sprite2D.new()
	var cache_key = str(element.type) + "_drag"
	if cache_key not in texture_cache:
		texture_cache[cache_key] = _create_drag_texture(element.color)
	
	drag_sprite.texture = texture_cache[cache_key]
	drag_sprite.z_index = 100  # Ensure it's on top
	add_child(drag_sprite)
	
	# Set initial position
	last_mouse_position = get_global_mouse_position()
	drag_sprite.global_position = last_mouse_position - drag_offset

func _unhandled_input(event):
	if is_dragging:
		if event is InputEventMouseMotion:
			# Performance optimization: only update if moved significantly
			var new_position = event.position
			if new_position.distance_to(last_mouse_position) > drag_update_threshold:
				if drag_sprite:
					drag_sprite.global_position = new_position - drag_offset
				last_mouse_position = new_position
		
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

func _create_drag_texture(color: Color) -> Texture2D:
	"""Create drag texture (slightly larger and with glow effect)"""
	var image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = Vector2(24, 24)
	var radius = 20
	
	# Draw with glow effect
	for x in range(48):
		for y in range(48):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				var alpha = 1.0 - (distance / radius) * 0.5
				var glow_color = Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, alpha)
				image.set_pixel(x, y, glow_color)
	
	return ImageTexture.create_from_image(image)

func cleanup_texture_cache():
	"""Clean up texture cache to free memory"""
	var cache_size_before = texture_cache.size()
	
	# Keep only the most frequently used textures
	# In a more sophisticated implementation, we could track usage frequency
	if texture_cache.size() > 20:
		var keys_to_remove = []
		var count = 0
		for key in texture_cache.keys():
			if count > 10:  # Keep only first 10 entries
				keys_to_remove.append(key)
			count += 1
		
		for key in keys_to_remove:
			texture_cache.erase(key)
	
	print("Texture cache cleanup: ", cache_size_before, " -> ", texture_cache.size(), " entries")
