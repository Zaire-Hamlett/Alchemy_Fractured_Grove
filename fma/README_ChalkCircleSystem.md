# Chalk Circle Drawing System for Godot

A comprehensive GDScript system for drawing chalk circles on a 2D canvas with touch input and detecting when the circle is complete. Perfect for games that require gesture-based circle drawing like transmutation circles, magic spells, or ritual systems.

## Features

- **Touch Input Support**: Works with touch screens and mouse input
- **Real-time Circle Detection**: Detects when a drawn shape is a complete circle
- **Chalk-like Visual Effects**: Realistic chalk texture with opacity variations
- **Progress Tracking**: Shows drawing progress in real-time
- **Visual Feedback**: Glow effects and progress indicators
- **Customizable Parameters**: Adjustable thresholds, colors, and sizes
- **Multiple Circle Support**: Track multiple circles for complex patterns

## Files Overview

### Core System Files

1. **`ChalkCircleDrawer.gd`** - Basic chalk circle drawing system
2. **`EnhancedChalkCircleDrawer.gd`** - Advanced version with visual feedback and progress tracking
3. **`ChalkTexture.gd`** - Generates realistic chalk-like textures
4. **`ChalkCircleDemo.gd`** - Demo UI controller
5. **`ChalkCircleExample.gd`** - Example integration for games

### Scene Files

1. **`ChalkCircleDemo.tscn`** - Complete demo scene showcasing the system

## Quick Start

### 1. Basic Usage

```gdscript
# Add the EnhancedChalkCircleDrawer to your scene
var chalk_drawer = EnhancedChalkCircleDrawer.new()
add_child(chalk_drawer)

# Connect to signals
chalk_drawer.circle_completed.connect(_on_circle_completed)
chalk_drawer.drawing_started.connect(_on_drawing_started)
chalk_drawer.drawing_ended.connect(_on_drawing_ended)
chalk_drawer.circle_progress.connect(_on_circle_progress)

func _on_circle_completed(center: Vector2, radius: float):
    print("Circle completed at: ", center, " with radius: ", radius)
```

### 2. Customization

```gdscript
# Configure the drawer
chalk_drawer.line_width = 5.0
chalk_drawer.chalk_color = Color.WHITE
chalk_drawer.completion_threshold = 0.1  # 10% tolerance for completion
chalk_drawer.min_circle_radius = 50.0
chalk_drawer.max_circle_radius = 300.0
chalk_drawer.use_chalk_texture = true
```

### 3. Multiple Circles

```gdscript
var completed_circles: Array[Dictionary] = []

func _on_circle_completed(center: Vector2, radius: float):
    var circle_info = {
        "center": center,
        "radius": radius,
        "timestamp": Time.get_time_dict_from_system()
    }
    completed_circles.append(circle_info)
    
    # Check for patterns
    if completed_circles.size() == 3:
        check_triangle_pattern()
```

## Configuration Parameters

### EnhancedChalkCircleDrawer Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `line_width` | float | 4.0 | Width of the chalk line |
| `chalk_color` | Color | Color.WHITE | Color of the chalk |
| `completion_threshold` | float | 0.12 | How close start/end points must be (12%) |
| `min_circle_radius` | float | 50.0 | Minimum valid circle radius |
| `max_circle_radius` | float | 300.0 | Maximum valid circle radius |
| `smoothing_factor` | float | 0.15 | Line smoothing amount |
| `use_chalk_texture` | bool | true | Enable chalk texture |
| `progress_indicator_color` | Color | Color.YELLOW | Progress indicator color |
| `completion_glow_color` | Color | Color.CYAN | Completion glow color |

## Signals

### EnhancedChalkCircleDrawer Signals

- `circle_completed(center: Vector2, radius: float)` - Emitted when a circle is completed
- `drawing_started()` - Emitted when drawing begins
- `drawing_ended()` - Emitted when drawing ends
- `circle_progress(progress: float)` - Emitted during drawing with progress (0.0 to 1.0)

## Methods

### Public Methods

```gdscript
# Clear the current drawing
chalk_drawer.clear_drawing()

# Get information about the current circle
var info = chalk_drawer.get_circle_info()
# Returns: {"is_complete": bool, "center": Vector2, "radius": float, "progress": float, "points_count": int}

# Change chalk color
chalk_drawer.set_chalk_color(Color.RED)
```

## Advanced Usage

### Pattern Detection

The system includes helper functions for detecting specific circle patterns:

```gdscript
# Check if circles form a triangle pattern
if check_triangle_pattern():
    print("Triangle pattern detected!")

# Check if circles are in a line
if check_line_pattern():
    print("Line pattern detected!")
```

### Integration with Game Systems

```gdscript
# Example: Transmutation system
func _on_circle_completed(center: Vector2, radius: float):
    var transmutation_type = determine_transmutation_type(center, radius)
    perform_transmutation(transmutation_type)

func determine_transmutation_type(center: Vector2, radius: float) -> String:
    if radius < 100:
        return "small_transmutation"
    elif radius < 200:
        return "medium_transmutation"
    else:
        return "large_transmutation"
```

## Performance Considerations

- The circle detection algorithm uses least squares fitting, which is efficient for most use cases
- Line smoothing is applied in real-time but can be disabled if performance is critical
- Chalk texture generation happens once at startup
- Visual effects (glow, progress indicators) can be disabled for better performance

## Troubleshooting

### Common Issues

1. **Circles not being detected**: 
   - Check that `completion_threshold` is not too strict
   - Ensure the drawn shape is roughly circular
   - Verify `min_circle_radius` and `max_circle_radius` settings

2. **Poor visual quality**:
   - Adjust `smoothing_factor` for smoother lines
   - Enable `use_chalk_texture` for better appearance
   - Increase `line_width` for more visible lines

3. **Performance issues**:
   - Disable `use_chalk_texture` if not needed
   - Reduce `smoothing_factor`
   - Limit the number of points collected

### Debug Information

```gdscript
# Get detailed circle information
var info = chalk_drawer.get_circle_info()
print("Circle info: ", info)

# Check if drawing is active
print("Is drawing: ", chalk_drawer.is_drawing)
```

## License

This system is provided as-is for educational and commercial use. Feel free to modify and integrate into your projects.

## Contributing

Feel free to submit improvements, bug fixes, or feature requests. The system is designed to be modular and extensible.
