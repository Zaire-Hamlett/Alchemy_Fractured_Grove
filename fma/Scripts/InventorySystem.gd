extends Node2D
class_name InventorySystem

signal item_selected(item: TransmutationSystem.Item)
signal item_used(item: TransmutationSystem.Item)

@export var inventory_size: int = 20
@export var slot_size: Vector2 = Vector2(60, 60)

var inventory_slots: Array[Button] = []
var inventory_items: Array[TransmutationSystem.Item] = []
var selected_item: TransmutationSystem.Item = null
var transmutation_system: TransmutationSystem

# Performance optimization
var ui_update_timer: float = 0.0
var ui_update_interval: float = 0.1  # Update UI every 100ms instead of every frame
var dirty_ui: bool = false
var cached_item_info: Dictionary = {}

func _ready():
	# Wait for viewport to be ready
	await get_tree().process_frame
	_setup_inventory_ui()

func _process(delta):
	# Throttled UI updates for better performance
	ui_update_timer += delta
	if ui_update_timer >= ui_update_interval and dirty_ui:
		_update_ui_display()
		dirty_ui = false
		ui_update_timer = 0.0

func _setup_inventory_ui():
	# Create inventory panel
	var inventory_panel = Panel.new()
	inventory_panel.size = Vector2(400, 300)
	inventory_panel.position = Vector2(get_viewport().size.x - 410, get_viewport().size.y - 310)
	inventory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(inventory_panel)
	
	# Create title
	var title = Label.new()
	title.text = "Inventory"
	title.position = Vector2(10, 10)
	title.add_theme_font_size_override("font_size", 18)
	inventory_panel.add_child(title)
	
	# Create inventory slots (optimized)
	_create_inventory_slots_optimized(inventory_panel)
	
	# Create item info panel (optimized)
	_create_item_info_panel()

func _create_inventory_slots_optimized(parent: Panel):
	"""Optimized inventory slot creation"""
	var slots_per_row = 6
	var start_pos = Vector2(10, 40)
	
	for i in range(inventory_size):
		var slot = _create_inventory_slot_optimized(i)
		
		var row = i / slots_per_row
		var col = i % slots_per_row
		slot.position = start_pos + Vector2(col * (slot_size.x + 5), row * (slot_size.y + 5))
		
		parent.add_child(slot)
		inventory_slots.append(slot)

func _create_inventory_slot_optimized(index: int) -> Button:
	"""Optimized slot creation with better event handling"""
	var slot = Button.new()
	slot.size = slot_size
	slot.name = "Slot" + str(index)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Connect slot click with optimized callback
	slot.pressed.connect(_on_slot_clicked.bind(index), CONNECT_DEFERRED)
	
	return slot

func _create_item_info_panel():
	"""Create optimized item info panel"""
	var info_panel = Panel.new()
	info_panel.size = Vector2(200, 150)
	info_panel.position = Vector2(10, get_viewport().size.y - 160)
	add_child(info_panel)
	
	# Item info labels (cached for reuse)
	var info_title = Label.new()
	info_title.text = "Item Info"
	info_title.position = Vector2(10, 10)
	info_title.add_theme_font_size_override("font_size", 14)
	info_panel.add_child(info_title)
	
	var item_name_label = Label.new()
	item_name_label.name = "ItemName"
	item_name_label.text = "No item selected"
	item_name_label.position = Vector2(10, 35)
	info_panel.add_child(item_name_label)
	
	var item_desc_label = Label.new()
	item_desc_label.name = "ItemDesc"
	item_desc_label.text = ""
	item_desc_label.position = Vector2(10, 55)
	item_desc_label.size = Vector2(180, 60)
	item_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_panel.add_child(item_desc_label)
	
	var item_rarity_label = Label.new()
	item_rarity_label.name = "ItemRarity"
	item_rarity_label.text = ""
	item_rarity_label.position = Vector2(10, 120)
	info_panel.add_child(item_rarity_label)

func _on_slot_clicked(index: int):
	"""Optimized slot click handling"""
	if index < inventory_items.size() and inventory_items[index]:
		selected_item = inventory_items[index]
		_update_item_info_cached(selected_item)
		item_selected.emit(selected_item)

func _update_item_info_cached(item: TransmutationSystem.Item):
	"""Optimized item info update with caching"""
	var cache_key = item.name + "_" + str(item.rarity)
	
	if cache_key not in cached_item_info:
		# Cache the item display info
		cached_item_info[cache_key] = {
			"name": item.name,
			"description": item.description,
			"rarity_text": _get_rarity_text(item.rarity),
			"rarity_color": _get_rarity_color(item.rarity)
		}
	
	var info = cached_item_info[cache_key]
	
	var name_label = find_child("ItemName", true, false)
	var desc_label = find_child("ItemDesc", true, false)
	var rarity_label = find_child("ItemRarity", true, false)
	
	if name_label:
		name_label.text = info.name
	if desc_label:
		desc_label.text = info.description
	if rarity_label:
		rarity_label.text = info.rarity_text
		rarity_label.modulate = info.rarity_color

func _get_rarity_name(rarity: TransmutationSystem.ItemRarity) -> String:
	match rarity:
		TransmutationSystem.ItemRarity.COMMON:
			return "Common"
		TransmutationSystem.ItemRarity.UNCOMMON:
			return "Uncommon"
		TransmutationSystem.ItemRarity.RARE:
			return "Rare"
		TransmutationSystem.ItemRarity.EPIC:
			return "Epic"
		TransmutationSystem.ItemRarity.LEGENDARY:
			return "Legendary"
		_:
			return "Unknown"

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

func add_item(item: TransmutationSystem.Item) -> bool:
	"""Optimized item addition"""
	if inventory_items.size() >= inventory_size:
		print("Inventory full!")
		return false
	
	inventory_items.append(item)
	dirty_ui = true  # Mark UI as needing update
	inventory_updated.emit()
	return true

func remove_item(index: int):
	if index >= 0 and index < inventory_items.size():
		inventory_items.remove_at(index)
		_update_inventory_display()
		return true
	return false

func _update_ui_display():
	"""Optimized UI display update"""
	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		if i < inventory_items.size() and inventory_items[i]:
			var item = inventory_items[i]
			slot.text = item.name
			slot.modulate = _get_rarity_color(item.rarity)
		else:
			slot.text = ""
			slot.modulate = Color.WHITE

func _create_item_texture(item: TransmutationSystem.Item) -> Texture2D:
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Create a simple item icon based on rarity
	var color = _get_rarity_color(item.rarity)
	
	# Draw item shape (simple rectangle with border)
	for x in range(32):
		for y in range(32):
			if x < 2 or x > 29 or y < 2 or y > 29:
				# Border
				image.set_pixel(x, y, Color.BLACK)
			elif x > 4 and x < 27 and y > 4 and y < 27:
				# Fill
				image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

func set_transmutation_system(system: TransmutationSystem):
	transmutation_system = system
	if transmutation_system:
		transmutation_system.inventory_updated.connect(_on_inventory_updated)
		transmutation_system.transmutation_completed.connect(_on_transmutation_completed)

func _on_inventory_updated():
	# Refresh inventory display
	_update_inventory_display()

func _on_transmutation_completed(recipe: TransmutationSystem.Recipe, result: TransmutationSystem.Item):
	# Add the result item to inventory
	add_item(result)
	
	# Show notification
	_show_item_notification(result)

func _show_item_notification(item: TransmutationSystem.Item):
	# Create notification popup
	var notification = Panel.new()
	notification.size = Vector2(200, 80)
	notification.position = Vector2(get_viewport().size.x / 2 - 100, 100)
	notification.modulate = Color.TRANSPARENT
	
	var label = Label.new()
	label.text = "Created: " + item.name
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 16)
	notification.add_child(label)
	
	get_tree().current_scene.add_child(notification)
	
	# Animate in
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 1.0, 0.3)
	tween.tween_property(notification, "modulate:a", 0.0, 0.3).set_delay(2.0)
	tween.tween_callback(func(): notification.queue_free())

func get_inventory_items() -> Array[TransmutationSystem.Item]:
	return inventory_items

func get_selected_item() -> TransmutationSystem.Item:
	return selected_item

func clear_selection():
	selected_item = null
	var name_label = find_child("ItemName", true, false)
	var desc_label = find_child("ItemDesc", true, false)
	var rarity_label = find_child("ItemRarity", true, false)
	
	if name_label:
		name_label.text = "No item selected"
	if desc_label:
		desc_label.text = ""
	if rarity_label:
		rarity_label.text = ""
