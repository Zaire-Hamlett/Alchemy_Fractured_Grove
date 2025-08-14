extends Node2D
class_name TransmutationSystem

signal transmutation_completed(recipe: Recipe, result: Item)
signal element_added(element: Element)
signal inventory_updated()

# Recipe database
var recipes: Array[Recipe] = []
var active_recipe: Recipe = null
var transmutation_in_progress: bool = false
var added_elements: Array[ElementType] = []  # Track which elements have been added

# Inventory system
var inventory: Array[Item] = []
var max_inventory_size: int = 20

# Element types
enum ElementType {
	FIRE,
	WATER,
	EARTH,
	AIR,
	METAL,
	ORGANIC,
	LIGHT,
	DARK,
	LIFE,
	DEATH,
	VOID,
	COPPER,
	TIN
}

# Item rarity
enum ItemRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

# Element class
class Element:
	var type: ElementType
	var name: String
	var color: Color
	var icon: Texture2D
	var description: String
	
	func _init(element_type: ElementType):
		type = element_type
		match type:
			ElementType.FIRE:
				name = "Fire"
				color = Color.RED
				description = "Burning energy of transformation"
			ElementType.WATER:
				name = "Water"
				color = Color.BLUE
				description = "Flowing force of change"
			ElementType.EARTH:
				name = "Earth"
				color = Color.BROWN
				description = "Solid foundation of creation"
			ElementType.AIR:
				name = "Air"
				color = Color.CYAN
				description = "Free spirit of movement"
			ElementType.METAL:
				name = "Metal"
				color = Color.SILVER
				description = "Unbreakable strength"
			ElementType.ORGANIC:
				name = "Organic"
				color = Color.GREEN
				description = "Growing life force"
			ElementType.LIGHT:
				name = "Light"
				color = Color.YELLOW
				description = "Pure illumination"
			ElementType.DARK:
				name = "Dark"
				color = Color.PURPLE
				description = "Mysterious power"
			ElementType.LIFE:
				name = "Life"
				color = Color.PINK
				description = "Vital essence"
			ElementType.DEATH:
				name = "Death"
				color = Color.BLACK
				description = "Ending transformation"
			ElementType.VOID:
				name = "Void"
				color = Color.DARK_GRAY
				description = "Absence of all things"
			ElementType.COPPER:
				name = "Copper"
				color = Color.ORANGE
				description = "Conductive metal of communication"
			ElementType.TIN:
				name = "Tin"
				color = Color.LIGHT_GRAY
				description = "Soft metal of flexibility"

# Item class
class Item:
	var name: String
	var description: String
	var rarity: ItemRarity
	var icon: Texture2D
	var stack_size: int = 1
	var max_stack: int = 99
	
	func _init(item_name: String, item_description: String, item_rarity: ItemRarity):
		name = item_name
		description = item_description
		rarity = item_rarity

# Recipe class
class Recipe:
	var name: String
	var description: String
	var required_elements: Array[ElementType]
	var result_item: Item
	var difficulty: int  # 1-10 scale
	var transmutation_time: float
	var success_rate: float
	
	func _init(recipe_name: String, recipe_description: String, elements: Array[ElementType], result: Item, diff: int, time: float, rate: float):
		name = recipe_name
		description = recipe_description
		required_elements = elements
		result_item = result
		difficulty = diff
		transmutation_time = time
		success_rate = rate

func _ready():
	_setup_recipes()

func _setup_recipes():
	print("Setting up recipes...")
	# Create basic items from the recipe table
	var stone_block = Item.new("Stone Block", "Stone remembers every step.", ItemRarity.COMMON)
	var iron_ingot = Item.new("Iron Ingot", "Iron is the blood of the earth.", ItemRarity.COMMON)
	var glass_shard = Item.new("Glass Shard", "Heat turns stone into frozen light.", ItemRarity.UNCOMMON)
	var steam_jet = Item.new("Steam Jet", "The breath of boiling rivers can power machines.", ItemRarity.UNCOMMON)
	var wood_plank = Item.new("Wood Plank", "Trees are nature's architecture.", ItemRarity.COMMON)
	var bronze_alloy = Item.new("Bronze Alloy", "Blend of strength and flexibility.", ItemRarity.UNCOMMON)
	var living_seed = Item.new("Living Seed", "Life begets life.", ItemRarity.RARE)
	var healing_salve = Item.new("Healing Salve", "Water carries the memory of healing.", ItemRarity.RARE)
	var energy_crystal = Item.new("Energy Crystal", "The void drinks fire, and crystallizes it.", ItemRarity.EPIC)
	var wind_turbine = Item.new("Wind Turbine", "Harness the sky's restless motion.", ItemRarity.EPIC)
	
	# Create structure items
	var campfire = Item.new("Campfire", "Every flame is a beacon in the dark. Attracts first traveler; allows cooking.", ItemRarity.UNCOMMON)
	var water_well = Item.new("Water Well", "Dig deep and you find the lifeblood of the land. Attracts settlers; improves health.", ItemRarity.UNCOMMON)
	var wooden_hut = Item.new("Wooden Hut", "Shelter is the first step to belonging. Houses one villager; starts population growth.", ItemRarity.RARE)
	var blacksmith_forge = Item.new("Blacksmith Forge", "Fire and metal sing in harmony here. Unlocks advanced metal crafting.", ItemRarity.RARE)
	var farm_plot = Item.new("Farm Plot", "The earth is patient, if you feed her. Produces Organic every turn; draws farmers.", ItemRarity.RARE)
	var marketplace = Item.new("Marketplace", "Where strangers meet, ideas flow. Enables trading rare materials with travelers.", ItemRarity.EPIC)
	var alchemy_laboratory = Item.new("Alchemy Laboratory", "The circle grows more intricate. Unlocks high-tier alchemy recipes.", ItemRarity.EPIC)
	var town_hall = Item.new("Town Hall", "Here, the village's heart beats. Doubles village capacity; attracts skilled NPCs.", ItemRarity.LEGENDARY)
	var watchtower = Item.new("Watchtower", "Eyes that see beyond the horizon. Improves defense; reveals events sooner.", ItemRarity.EPIC)
	
	# Add recipes from the table
	recipes.append(Recipe.new("Stone Block", "Combine earth twice for solid foundation", 
		[ElementType.EARTH, ElementType.EARTH], stone_block, 1, 1.0, 0.9))
	
	recipes.append(Recipe.new("Iron Ingot", "Refine metal twice for pure strength", 
		[ElementType.METAL, ElementType.METAL], iron_ingot, 2, 1.5, 0.8))
	
	recipes.append(Recipe.new("Glass Shard", "Heat earth with fire to create transparency", 
		[ElementType.EARTH, ElementType.FIRE], glass_shard, 3, 2.0, 0.7))
	
	recipes.append(Recipe.new("Steam Jet", "Combine water and fire for power", 
		[ElementType.WATER, ElementType.FIRE], steam_jet, 3, 2.0, 0.8))
	
	recipes.append(Recipe.new("Wood Plank", "Organic material shaped by nature", 
		[ElementType.ORGANIC, ElementType.ORGANIC], wood_plank, 1, 1.0, 0.9))
	
	recipes.append(Recipe.new("Bronze Alloy", "Blend copper and tin for flexibility", 
		[ElementType.COPPER, ElementType.TIN], bronze_alloy, 4, 2.5, 0.7))
	
	recipes.append(Recipe.new("Living Seed", "Infuse organic matter with life essence", 
		[ElementType.ORGANIC, ElementType.LIFE], living_seed, 5, 3.0, 0.6))
	
	recipes.append(Recipe.new("Healing Salve", "Combine organic, water, and life for healing", 
		[ElementType.ORGANIC, ElementType.WATER, ElementType.LIFE], healing_salve, 6, 3.5, 0.5))
	
	recipes.append(Recipe.new("Energy Crystal", "Void consumes fire to create energy", 
		[ElementType.FIRE, ElementType.VOID], energy_crystal, 7, 4.0, 0.4))
	
	# Note: Wind Turbine requires Energy Crystal item, which would need special handling
	# For now, let's make it a simpler recipe
	recipes.append(Recipe.new("Wind Turbine", "Combine metal and air for wind power", 
		[ElementType.METAL, ElementType.AIR], wind_turbine, 5, 3.0, 0.6))
	
	# Add structure recipes (these would need item-based system for full implementation)
	# For now, I'll create simplified versions using elements
	recipes.append(Recipe.new("Campfire", "Combine fire twice with organic for warmth", 
		[ElementType.FIRE, ElementType.FIRE, ElementType.ORGANIC], campfire, 4, 2.5, 0.8))
	
	recipes.append(Recipe.new("Water Well", "Combine earth twice with water twice for sustenance", 
		[ElementType.EARTH, ElementType.EARTH, ElementType.WATER, ElementType.WATER], water_well, 5, 3.0, 0.7))
	
	recipes.append(Recipe.new("Wooden Hut", "Combine organic three times with life for shelter", 
		[ElementType.ORGANIC, ElementType.ORGANIC, ElementType.ORGANIC, ElementType.LIFE], wooden_hut, 6, 3.5, 0.6))
	
	recipes.append(Recipe.new("Blacksmith Forge", "Combine earth four times with fire and metal twice", 
		[ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.FIRE, ElementType.METAL, ElementType.METAL], blacksmith_forge, 8, 4.0, 0.5))
	
	recipes.append(Recipe.new("Farm Plot", "Combine organic three times with water twice and life", 
		[ElementType.ORGANIC, ElementType.ORGANIC, ElementType.ORGANIC, ElementType.WATER, ElementType.WATER, ElementType.LIFE], farm_plot, 7, 3.5, 0.6))
	
	recipes.append(Recipe.new("Marketplace", "Combine organic three times with earth three times and air", 
		[ElementType.ORGANIC, ElementType.ORGANIC, ElementType.ORGANIC, ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.AIR], marketplace, 9, 4.5, 0.4))
	
	recipes.append(Recipe.new("Alchemy Laboratory", "Combine earth six times with fire and void", 
		[ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.FIRE, ElementType.VOID], alchemy_laboratory, 10, 5.0, 0.3))
	
	recipes.append(Recipe.new("Town Hall", "Combine earth ten times with metal four times and life three times", 
		[ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.EARTH, ElementType.METAL, ElementType.METAL, ElementType.METAL, ElementType.METAL, ElementType.LIFE, ElementType.LIFE, ElementType.LIFE], town_hall, 12, 6.0, 0.2))
	
	recipes.append(Recipe.new("Watchtower", "Combine organic five times with metal twice and air", 
		[ElementType.ORGANIC, ElementType.ORGANIC, ElementType.ORGANIC, ElementType.ORGANIC, ElementType.ORGANIC, ElementType.METAL, ElementType.METAL, ElementType.AIR], watchtower, 8, 4.0, 0.5))
	
	print("Created ", recipes.size(), " recipes:")
	for recipe in recipes:
		print("  - ", recipe.name, " (", recipe.required_elements.size(), " elements)")

func add_element_to_circle(element: Element, circle_center: Vector2):
	print("Adding element: ", element.name, " (", element.type, ")")
	print("Current state - Active recipe: ", active_recipe.name if active_recipe else "None", ", Added elements: ", added_elements, ", In progress: ", transmutation_in_progress)
	print("Active recipe object: ", active_recipe)
	
	# If no active recipe, find one that matches this element
	if active_recipe == null:
		print("No active recipe, searching for matching recipe...")
		
		# First, look for recipes that require multiple instances of this element
		var best_recipe = null
		var max_element_count = 0
		
		for recipe in recipes:
			if element.type in recipe.required_elements:
				var element_count = recipe.required_elements.count(element.type)
				if element_count > max_element_count:
					max_element_count = element_count
					best_recipe = recipe
		
		# If we found a recipe with multiple instances, use it
		if best_recipe and max_element_count > 1:
			print("Found recipe requiring multiple instances: ", best_recipe.name, " (", max_element_count, "x ", element.name, ")")
			active_recipe = best_recipe
			added_elements.clear()
			added_elements.append(element.type)
			element_added.emit(element)
			_start_transmutation_animation(circle_center, element)
			return true
		
		# Otherwise, use the first matching recipe (original behavior)
		for recipe in recipes:
			if element.type in recipe.required_elements:
				print("Found matching recipe: ", recipe.name)
				active_recipe = recipe
				added_elements.clear()
				added_elements.append(element.type)
				element_added.emit(element)
				_start_transmutation_animation(circle_center, element)
				return true
		print("No matching recipe found for element: ", element.name)
		return false
	
	# If we have an active recipe, check if this element is needed
	if element.type in active_recipe.required_elements:
		# Check if we can add more of this element type
		var current_count = added_elements.count(element.type)
		var required_count = active_recipe.required_elements.count(element.type)
		
		if current_count >= required_count:
			print("Element already added maximum times: ", element.name, " (", current_count, "/", required_count, ")")
			return false  # Element already added maximum times
		
		# Add the element
		added_elements.append(element.type)
		print("Added element: ", element.name, ". Total elements: ", added_elements.size(), "/", active_recipe.required_elements.size(), " (", element.name, ": ", current_count + 1, "/", required_count, ")")
		element_added.emit(element)
		_continue_transmutation_animation(circle_center, element)
		
		# Check if we have all required elements
		if _check_recipe_completion():
			print("Recipe complete! Completing transmutation...")
			_complete_transmutation(circle_center)
		
		return true
	
	print("Element not needed for current recipe: ", element.name)
	return false

func _check_recipe_completion() -> bool:
	if active_recipe == null:
		return false
	
	# Check if we have all required elements
	for required_element in active_recipe.required_elements:
		if required_element not in added_elements:
			return false
	
	return true

func _start_transmutation_animation(center: Vector2, element: Element):
	print("Starting transmutation animation for: ", element.name)
	
	# Create element particle effect
	var element_particles = _create_element_particles(element, center)
	add_child(element_particles)
	print("Element particles created and added")

func _continue_transmutation_animation(center: Vector2, element: Element):
	print("Continuing transmutation animation for: ", element.name)
	# Add more particles for additional elements
	var element_particles = _create_element_particles(element, center)
	add_child(element_particles)
	print("Additional element particles created and added")

func _create_element_particles(element: Element, position: Vector2) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 80.0
	material.angular_velocity_min = -360.0
	material.angular_velocity_max = 360.0
	material.gravity = Vector3(0, -20.0, 0)
	material.lifetime_randomness = 0.2
	
	# Scale
	material.scale_min = 0.8
	material.scale_max = 2.0
	
	# Color over lifetime
	material.color_ramp = GradientTexture1D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(element.color.r, element.color.g, element.color.b, 1.0))
	gradient.add_point(0.7, Color(element.color.r, element.color.g, element.color.b, 0.6))
	gradient.add_point(1.0, Color(element.color.r, element.color.g, element.color.b, 0.0))
	material.color_ramp.gradient = gradient
	
	particles.process_material = material
	particles.amount = 50
	particles.lifetime = 2.0
	particles.one_shot = true
	particles.explosiveness = 0.3
	particles.position = position
	
	# Create element texture
	var element_texture = _create_element_texture(element.color)
	particles.texture = element_texture
	
	return particles

func _create_element_texture(color: Color) -> Texture2D:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw a glowing circle
	for x in range(16):
		for y in range(16):
			var distance = Vector2(x - 8, y - 8).length()
			if distance <= 7:
				var alpha = 1.0 - (distance / 7.0)
				alpha = alpha * alpha  # Square for better glow effect
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	return ImageTexture.create_from_image(image)

func _complete_transmutation(center: Vector2):
	print("Completing transmutation...")
	transmutation_in_progress = true  # Set to true to prevent further additions during completion
	
	# Calculate success based on recipe difficulty and random chance
	var success = randf() <= active_recipe.success_rate
	print("Transmutation success: ", success, " (rate: ", active_recipe.success_rate, ")")
	
	if success:
		# Create result item
		var result_item = active_recipe.result_item
		print("Creating item: ", result_item.name)
		add_item_to_inventory(result_item)
		
		# Show success animation
		_show_success_animation(center, result_item)
		
		transmutation_completed.emit(active_recipe, result_item)
		print("Transmutation completed successfully!")
	else:
		# Show failure animation
		_show_failure_animation(center)
		print("Transmutation failed!")
	
	# Reset active recipe and elements
	active_recipe = null
	added_elements.clear()
	transmutation_in_progress = false  # Reset for next transmutation

func _show_success_animation(center: Vector2, item: Item):
	# Create golden particle burst
	var success_particles = GPUParticles2D.new()
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 50.0
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 200.0
	material.angular_velocity_min = -720.0
	material.angular_velocity_max = 720.0
	material.gravity = Vector3(0, -50.0, 0)
	material.lifetime_randomness = 0.3
	
	# Scale
	material.scale_min = 1.0
	material.scale_max = 3.0
	
	# Golden color
	material.color_ramp = GradientTexture1D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.GOLD)
	gradient.add_point(0.5, Color.YELLOW)
	gradient.add_point(1.0, Color.TRANSPARENT)
	material.color_ramp.gradient = gradient
	
	success_particles.process_material = material
	success_particles.amount = 100
	success_particles.lifetime = 3.0
	success_particles.one_shot = true
	success_particles.explosiveness = 1.0
	success_particles.position = center
	
	add_child(success_particles)
	
	# Remove particles after animation
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func(): success_particles.queue_free())

func _show_failure_animation(center: Vector2):
	# Create dark smoke effect
	var failure_particles = GPUParticles2D.new()
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 60.0
	material.angular_velocity_min = -180.0
	material.angular_velocity_max = 180.0
	material.gravity = Vector3(0, -10.0, 0)
	material.lifetime_randomness = 0.4
	
	# Scale
	material.scale_min = 2.0
	material.scale_max = 5.0
	
	# Dark smoke color
	material.color_ramp = GradientTexture1D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.DARK_GRAY)
	gradient.add_point(0.5, Color.GRAY)
	gradient.add_point(1.0, Color.TRANSPARENT)
	material.color_ramp.gradient = gradient
	
	failure_particles.process_material = material
	failure_particles.amount = 80
	failure_particles.lifetime = 2.0
	failure_particles.one_shot = true
	failure_particles.explosiveness = 0.5
	failure_particles.position = center
	
	add_child(failure_particles)
	
	# Remove particles after animation
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): failure_particles.queue_free())

func add_item_to_inventory(item: Item):
	print("Adding item to inventory: ", item.name)
	if inventory.size() < max_inventory_size:
		inventory.append(item)
		print("Item added successfully. Inventory size: ", inventory.size())
		inventory_updated.emit()
		return true
	print("Inventory full! Cannot add item: ", item.name)
	return false

func remove_item_from_inventory(index: int):
	if index >= 0 and index < inventory.size():
		inventory.remove_at(index)
		inventory_updated.emit()
		return true
	return false

func get_inventory() -> Array[Item]:
	return inventory

func get_recipes() -> Array[Recipe]:
	return recipes

func get_active_recipe() -> Recipe:
	return active_recipe

func is_transmutation_in_progress() -> bool:
	return transmutation_in_progress

func get_element_by_type(type: ElementType) -> Element:
	return Element.new(type)

func reset_transmutation():
	print("Resetting transmutation system...")
	print("Before reset - Active recipe: ", active_recipe, ", Added elements: ", added_elements)
	# Reset the transmutation system for a new circle
	active_recipe = null
	added_elements = []  # Recreate the array instead of just clearing
	transmutation_in_progress = false
	print("After reset - Active recipe: ", active_recipe, ", Added elements: ", added_elements)
	print("Transmutation system reset complete - Active recipe: ", active_recipe, ", Added elements: ", added_elements)
