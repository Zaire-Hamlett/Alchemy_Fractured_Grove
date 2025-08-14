# Transmutation Crafting System

A comprehensive crafting system for Godot 4 that combines chalk circle drawing with element-based transmutation, inspired by Fullmetal Alchemist.

## Features

### 🎨 **Chalk Circle Drawing**
- **Mouse & Touch Input**: Draw circles with mouse or touch
- **Accessibility**: Hold 'E' key for auto-completion
- **Visual Feedback**: Chalk dust particles, progress indicators, completion glow
- **Circle Detection**: Advanced algorithm to detect completed circles

### 🔮 **Element System**
- **10 Element Types**: Fire, Water, Earth, Air, Metal, Wood, Light, Dark, Life, Death
- **Drag & Drop**: Intuitive element dragging onto completed circles
- **Visual Elements**: Each element has unique colors and particle effects

### 📚 **Recipe Database**
- **6 Built-in Recipes**: From simple potions to legendary items
- **Recipe Book UI**: Browse available recipes with details
- **Difficulty System**: 1-10 scale with color coding
- **Success Rates**: Variable success based on recipe difficulty

### 🎒 **Inventory Management**
- **20-Slot Inventory**: Store crafted items
- **Item Rarity System**: Common, Uncommon, Rare, Epic, Legendary
- **Item Information**: Detailed item descriptions and stats
- **Visual Feedback**: Color-coded rarity and notifications

### ✨ **Animation System**
- **Element Particles**: Unique particle effects for each element
- **Transmutation Animations**: Success/failure visual feedback
- **Completion Effects**: Golden bursts for success, dark smoke for failure

## How to Use

### 1. **Drawing Circles**
```
Mouse: Click and drag to draw
Touch: Tap and drag on touch devices
Keyboard: Hold 'E' key for auto-completion
```

### 2. **Crafting Process**
```
1. Draw a complete transmutation circle
2. Drag elements from the top panel onto the circle
3. Wait for transmutation to complete
4. Collect your crafted item in the inventory
```

### 3. **Recipe Discovery**
```
- Check the Recipe Book (top-right panel)
- Click on recipes to see detailed requirements
- Elements needed are color-coded
- Difficulty and success rates are shown
```

## Built-in Recipes

| Recipe | Elements Required | Difficulty | Success Rate | Result |
|--------|------------------|------------|--------------|---------|
| Fire Sword | Fire + Metal | 3/10 | 80% | Uncommon Weapon |
| Healing Potion | Water + Life | 2/10 | 90% | Common Consumable |
| Stone Shield | Earth + Metal | 4/10 | 70% | Rare Defense |
| Wind Dagger | Air + Metal | 3/10 | 80% | Uncommon Weapon |
| Steel Armor | Metal + Earth + Fire | 6/10 | 60% | Rare Armor |
| Life Crystal | Life + Light + Water | 8/10 | 50% | Epic Artifact |

## File Structure

```
Scripts/
├── GameManager.gd              # Main game coordinator
├── TransmutationSystem.gd      # Core crafting logic
├── ElementDragSystem.gd        # Drag & drop system
├── InventorySystem.gd          # Inventory management
├── RecipeBook.gd              # Recipe database UI
└── EnhancedChalkCircleDrawer.gd # Circle drawing system

Scenes/
└── TransmutationGame.tscn     # Main game scene
```

## System Architecture

### **GameManager**
- Coordinates all subsystems
- Manages game state and UI
- Handles signal connections
- Provides status updates

### **TransmutationSystem**
- Recipe database management
- Element combination logic
- Success/failure calculations
- Animation coordination

### **ElementDragSystem**
- Element panel creation
- Drag & drop functionality
- Circle detection for drops
- Visual feedback

### **InventorySystem**
- Item storage and retrieval
- UI management
- Rarity color coding
- Notification system

### **RecipeBook**
- Recipe browsing interface
- Detailed recipe information
- Pagination system
- Difficulty indicators

## Customization

### **Adding New Elements**
```gdscript
# In TransmutationSystem.gd, add to ElementType enum:
enum ElementType {
    FIRE, WATER, EARTH, AIR, METAL, WOOD, LIGHT, DARK, LIFE, DEATH,
    YOUR_NEW_ELEMENT  # Add here
}

# Then add to Element class _init function:
match type:
    ElementType.YOUR_NEW_ELEMENT:
        name = "Your Element"
        color = Color.YOUR_COLOR
        description = "Your description"
```

### **Adding New Recipes**
```gdscript
# In TransmutationSystem._setup_recipes():
var your_item = Item.new("Your Item", "Description", ItemRarity.RARE)
recipes.append(Recipe.new(
    "Your Recipe",           # Recipe name
    "Description",           # Recipe description
    [ElementType.FIRE, ElementType.WATER],  # Required elements
    your_item,              # Result item
    5,                      # Difficulty (1-10)
    2.5,                    # Transmutation time
    0.75                    # Success rate
))
```

### **Modifying Success Rates**
```gdscript
# Adjust success rates in recipe creation:
success_rate = 0.9  # 90% success rate
```

## Performance Considerations

- **Particle Systems**: Automatically clean up after animations
- **Memory Management**: Efficient texture generation and reuse
- **UI Updates**: Only refresh when necessary
- **Circle Detection**: Optimized algorithms for real-time performance

## Accessibility Features

- **Keyboard Support**: 'E' key for circle completion
- **Visual Feedback**: Clear status messages and color coding
- **Tooltips**: Hover information for all interactive elements
- **High Contrast**: Distinct colors for different element types

## Future Enhancements

- **Save/Load System**: Persist inventory and progress
- **More Recipes**: Expand recipe database
- **Element Combinations**: Complex multi-element recipes
- **Achievement System**: Track crafting milestones
- **Sound Effects**: Audio feedback for actions
- **Multiplayer**: Collaborative crafting

## Troubleshooting

### **Circle Not Detecting**
- Ensure circle is complete (start and end points close)
- Check minimum/maximum radius settings
- Verify drawing quality threshold

### **Elements Not Dropping**
- Confirm circle is completed first
- Check drop zone proximity
- Verify element drag system is enabled

### **Transmutation Failing**
- Check recipe requirements match
- Verify success rate settings
- Ensure all elements are properly added

## License

This system is designed for educational and game development purposes. Feel free to modify and extend for your projects.
