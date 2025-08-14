extends Node2D
class_name GameManager

# Core systems
var chalk_circle_drawer: EnhancedChalkCircleDrawer
var element_drag_system: ElementDragSystem
var inventory_system: InventorySystem
var recipe_book: RecipeBook
var transmutation_system: TransmutationSystem

# UI elements
var status_label: Label
var instructions_label: Label

func _ready():
	_setup_game_systems()
	_setup_ui()
	_connect_signals()

func _setup_game_systems():
	# Create chalk circle drawer
	chalk_circle_drawer = EnhancedChalkCircleDrawer.new()
	add_child(chalk_circle_drawer)
	
	# Create transmutation system
	transmutation_system = TransmutationSystem.new()
	add_child(transmutation_system)
	
	# Create element drag system
	element_drag_system = ElementDragSystem.new()
	element_drag_system.set_chalk_circle_drawer(chalk_circle_drawer)
	element_drag_system.set_transmutation_system(transmutation_system)
	add_child(element_drag_system)
	
	# Create inventory system
	inventory_system = InventorySystem.new()
	inventory_system.set_transmutation_system(transmutation_system)
	add_child(inventory_system)
	
	# Create recipe book
	recipe_book = RecipeBook.new()
	recipe_book.set_transmutation_system(transmutation_system)
	add_child(recipe_book)

func _setup_ui():
	# Create status label
	status_label = Label.new()
	status_label.text = "Draw a transmutation circle to begin crafting!"
	status_label.position = Vector2(10, 220)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.modulate = Color.YELLOW
	add_child(status_label)
	
	# Create instructions label
	instructions_label = Label.new()
	instructions_label.text = "Instructions:\n1. Draw a circle with mouse or hold 'E'\n2. Drag elements from the top panel onto the circle\n3. Check the recipe book for available recipes\n4. View your inventory in the bottom panel"
	instructions_label.position = Vector2(10, 250)
	instructions_label.add_theme_font_size_override("font_size", 12)
	instructions_label.modulate = Color.LIGHT_GRAY
	instructions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions_label.size = Vector2(300, 100)
	add_child(instructions_label)

func _connect_signals():
	# Connect chalk circle signals
	chalk_circle_drawer.circle_completed.connect(_on_circle_completed)
	chalk_circle_drawer.drawing_started.connect(_on_drawing_started)
	chalk_circle_drawer.drawing_ended.connect(_on_drawing_ended)
	
	# Connect element drag signals
	element_drag_system.element_dropped.connect(_on_element_dropped)
	
	# Connect transmutation signals
	transmutation_system.element_added.connect(_on_element_added)
	transmutation_system.transmutation_completed.connect(_on_transmutation_completed)
	
	# Connect recipe book signals
	recipe_book.recipe_selected.connect(_on_recipe_selected)

func _on_circle_completed(center: Vector2, radius: float):
	print("Circle completed!")
	status_label.text = "Circle completed! Drag elements onto it to begin transmutation."
	status_label.modulate = Color.GREEN
	
	# Don't reset here - let the transmutation system handle its own state
	# The reset should only happen when starting a new drawing
	print("Circle completed - transmutation system ready for elements")
	
	# Enable element dragging
	element_drag_system.modulate = Color.WHITE
	
	# Mark the circle as ready for use
	chalk_circle_drawer.set_circle_in_use(true)

func _on_drawing_started():
	print("Drawing started!")
	status_label.text = "Drawing transmutation circle..."
	status_label.modulate = Color.CYAN
	
	# Don't reset here - let the transmutation system handle its own state
	# The reset should only happen when the circle is actually cleared
	print("Drawing started - transmutation system state preserved")

func clear_circle():
	"""Public function to clear the current circle and reset systems"""
	chalk_circle_drawer.clear_circle()
	transmutation_system.reset_transmutation()
	status_label.text = "Circle cleared! Draw a new transmutation circle."
	status_label.modulate = Color.YELLOW
	print("Circle manually cleared")

func _on_drawing_ended():
	if not chalk_circle_drawer.get_circle_info()["is_complete"]:
		status_label.text = "Incomplete circle. Try again!"
		status_label.modulate = Color.RED
		# Reset transmutation system for incomplete circle
		print("Incomplete circle - resetting transmutation system")
		transmutation_system.reset_transmutation()
	else:
		print("Circle completed successfully - transmutation system ready")

func _on_element_dropped(element: TransmutationSystem.Element, position: Vector2):
	status_label.text = "Added " + element.name + " to the transmutation!"
	status_label.modulate = element.color

func _on_element_added(element: TransmutationSystem.Element):
	var active_recipe = transmutation_system.get_active_recipe()
	if active_recipe:
		status_label.text = "Transmutation in progress: " + active_recipe.name
		status_label.modulate = Color.ORANGE

func _on_transmutation_completed(recipe: TransmutationSystem.Recipe, result: TransmutationSystem.Item):
	status_label.text = "Successfully created " + result.name + "!"
	status_label.modulate = _get_rarity_color(result.rarity)
	
	# Mark the circle as no longer in use after transmutation
	chalk_circle_drawer.set_circle_in_use(false)
	
	# Clear the circle for next use
	chalk_circle_drawer.clear_drawing()
	
	# Disable element dragging until new circle is drawn
	element_drag_system.modulate = Color.GRAY

func _on_recipe_selected(recipe: TransmutationSystem.Recipe):
	status_label.text = "Selected recipe: " + recipe.name
	status_label.modulate = _get_difficulty_color(recipe.difficulty)

func _get_rarity_color(rarity: TransmutationSystem.ItemRarity) -> Color:
	match rarity:
		TransmutationSystem.ItemRarity.COMMON:
			return Color.WHITE
		TransmutationSystem.ItemRarity.UNCOMMON:
			return Color.GREEN
		TransmutationSystem.ItemRarity.RARE:
			return Color.BLUE
		TransmutationSystem.ItemRarity.EPIC:
			return Color.PURPLE
		TransmutationSystem.ItemRarity.LEGENDARY:
			return Color.ORANGE
		_:
			return Color.WHITE

func _get_difficulty_color(difficulty: int) -> Color:
	match difficulty:
		1, 2:
			return Color.GREEN
		3, 4:
			return Color.YELLOW
		5, 6:
			return Color.ORANGE
		7, 8:
			return Color.RED
		9, 10:
			return Color.PURPLE
		_:
			return Color.WHITE

func get_chalk_circle_drawer() -> EnhancedChalkCircleDrawer:
	return chalk_circle_drawer

func get_transmutation_system() -> TransmutationSystem:
	return transmutation_system

func get_inventory_system() -> InventorySystem:
	return inventory_system

func get_recipe_book() -> RecipeBook:
	return recipe_book

func get_element_drag_system() -> ElementDragSystem:
	return element_drag_system
