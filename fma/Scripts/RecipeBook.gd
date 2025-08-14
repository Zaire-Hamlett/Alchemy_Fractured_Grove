extends Node2D
class_name RecipeBook

signal recipe_selected(recipe: TransmutationSystem.Recipe)

@export var recipes_per_page: int = 6

var current_page: int = 0
var recipes: Array[TransmutationSystem.Recipe] = []
var recipe_buttons: Array[Button] = []
var transmutation_system: TransmutationSystem

func _ready():
	# Wait for viewport to be ready
	await get_tree().process_frame
	_setup_recipe_book_ui()

func _setup_recipe_book_ui():
	# Create recipe book panel
	var recipe_panel = Panel.new()
	recipe_panel.size = Vector2(350, 400)
	recipe_panel.position = Vector2(get_viewport().size.x - 360, 10)
	recipe_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(recipe_panel)
	
	# Create title
	var title = Label.new()
	title.text = "Recipe Book"
	title.position = Vector2(10, 10)
	title.add_theme_font_size_override("font_size", 18)
	recipe_panel.add_child(title)
	
	# Create recipe list container
	var recipe_container = VBoxContainer.new()
	recipe_container.position = Vector2(10, 40)
	recipe_container.size = Vector2(330, 300)
	recipe_panel.add_child(recipe_container)
	
	# Create navigation buttons
	var nav_panel = HBoxContainer.new()
	nav_panel.position = Vector2(10, 350)
	nav_panel.size = Vector2(330, 40)
	recipe_panel.add_child(nav_panel)
	
	var prev_button = Button.new()
	prev_button.text = "Previous"
	prev_button.pressed.connect(_previous_page)
	nav_panel.add_child(prev_button)
	
	var page_label = Label.new()
	page_label.name = "PageLabel"
	page_label.text = "Page 1"
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_panel.add_child(page_label)
	
	var next_button = Button.new()
	next_button.text = "Next"
	next_button.pressed.connect(_next_page)
	nav_panel.add_child(next_button)

func set_transmutation_system(system: TransmutationSystem):
	transmutation_system = system
	if transmutation_system:
		recipes = transmutation_system.get_recipes()
		_update_recipe_display()

func _update_recipe_display():
	# Clear existing recipe buttons
	for button in recipe_buttons:
		button.queue_free()
	recipe_buttons.clear()
	
	# Calculate page bounds
	var start_index = current_page * recipes_per_page
	var end_index = min(start_index + recipes_per_page, recipes.size())
	
	# Create recipe buttons for current page
	for i in range(start_index, end_index):
		var recipe = recipes[i]
		var button = _create_recipe_button(recipe)
		recipe_buttons.append(button)
		
		# Add to container
		var container = find_child("VBoxContainer", true, false)
		if container:
			container.add_child(button)
	
	# Update page label
	var page_label = find_child("PageLabel", true, false)
	if page_label:
		var total_pages = (recipes.size() + recipes_per_page - 1) / recipes_per_page
		page_label.text = "Page " + str(current_page + 1) + " / " + str(total_pages)

func _create_recipe_button(recipe: TransmutationSystem.Recipe) -> Button:
	var button = Button.new()
	button.size = Vector2(320, 80)
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Create recipe info
	var recipe_info = VBoxContainer.new()
	recipe_info.size = Vector2(300, 70)
	button.add_child(recipe_info)
	
	# Recipe name
	var name_label = Label.new()
	name_label.text = recipe.name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.modulate = _get_difficulty_color(recipe.difficulty)
	recipe_info.add_child(name_label)
	
	# Recipe description
	var desc_label = Label.new()
	desc_label.text = recipe.description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.modulate = Color.GRAY
	recipe_info.add_child(desc_label)
	
	# Required elements
	var elements_label = Label.new()
	elements_label.text = "Required: " + _get_elements_string(recipe.required_elements)
	elements_label.add_theme_font_size_override("font_size", 10)
	elements_label.modulate = Color.LIGHT_BLUE
	recipe_info.add_child(elements_label)
	
	# Connect button press
	button.pressed.connect(func(): _on_recipe_selected(recipe))
	
	return button

func _get_elements_string(elements: Array[TransmutationSystem.ElementType]) -> String:
	var element_names = []
	for element_type in elements:
		var element = TransmutationSystem.Element.new(element_type)
		element_names.append(element.name)
	return ", ".join(element_names)

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

func _on_recipe_selected(recipe: TransmutationSystem.Recipe):
	recipe_selected.emit(recipe)
	_show_recipe_details(recipe)

func _show_recipe_details(recipe: TransmutationSystem.Recipe):
	# Create detail popup
	var detail_panel = Panel.new()
	detail_panel.size = Vector2(300, 250)
	detail_panel.position = Vector2(get_viewport().size.x / 2 - 150, get_viewport().size.y / 2 - 125)
	detail_panel.modulate = Color.TRANSPARENT
	
	var container = VBoxContainer.new()
	container.position = Vector2(10, 10)
	container.size = Vector2(280, 230)
	detail_panel.add_child(container)
	
	# Recipe name
	var name_label = Label.new()
	name_label.text = recipe.name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.modulate = _get_difficulty_color(recipe.difficulty)
	container.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = recipe.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(desc_label)
	
	# Required elements
	var req_label = Label.new()
	req_label.text = "Required Elements:"
	req_label.add_theme_font_size_override("font_size", 14)
	container.add_child(req_label)
	
	var elements_container = HBoxContainer.new()
	container.add_child(elements_container)
	
	for element_type in recipe.required_elements:
		var element = TransmutationSystem.Element.new(element_type)
		var element_button = Button.new()
		element_button.size = Vector2(40, 40)
		element_button.icon = _create_element_icon(element.color)
		element_button.tooltip_text = element.name
		elements_container.add_child(element_button)
	
	# Recipe stats
	var stats_label = Label.new()
	stats_label.text = "Difficulty: " + str(recipe.difficulty) + "/10"
	stats_label.modulate = _get_difficulty_color(recipe.difficulty)
	container.add_child(stats_label)
	
	var time_label = Label.new()
	time_label.text = "Transmutation Time: " + str(recipe.transmutation_time) + "s"
	container.add_child(time_label)
	
	var success_label = Label.new()
	success_label.text = "Success Rate: " + str(int(recipe.success_rate * 100)) + "%"
	container.add_child(success_label)
	
	# Result item
	var result_label = Label.new()
	result_label.text = "Result: " + recipe.result_item.name
	result_label.modulate = _get_rarity_color(recipe.result_item.rarity)
	container.add_child(result_label)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(func(): detail_panel.queue_free())
	container.add_child(close_button)
	
	get_tree().current_scene.add_child(detail_panel)
	
	# Animate in
	var tween = create_tween()
	tween.tween_property(detail_panel, "modulate:a", 1.0, 0.3)

func _create_element_icon(color: Color) -> Texture2D:
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	for x in range(32):
		for y in range(32):
			var distance = Vector2(x - 16, y - 16).length()
			if distance <= 14:
				var alpha = 1.0 - (distance / 14.0)
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	return ImageTexture.create_from_image(image)

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

func _previous_page():
	if current_page > 0:
		current_page -= 1
		_update_recipe_display()

func _next_page():
	var total_pages = (recipes.size() + recipes_per_page - 1) / recipes_per_page
	if current_page < total_pages - 1:
		current_page += 1
		_update_recipe_display()

func refresh_recipes():
	if transmutation_system:
		recipes = transmutation_system.get_recipes()
		_update_recipe_display()
