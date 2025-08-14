extends Node2D
class_name ChalkTexture

@export var texture_size: Vector2 = Vector2(64, 64)
@export var chalk_color: Color = Color.WHITE
@export var noise_scale: float = 8.0
@export var opacity_variation: float = 0.3
@export var texture_detail: float = 0.5

var noise: FastNoiseLite
var chalk_texture: ImageTexture

func _ready():
	_generate_chalk_texture()

func _generate_chalk_texture():
	# Create noise for chalk texture
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	noise.seed = randi()
	
	# Create image for texture
	var image = Image.create(int(texture_size.x), int(texture_size.y), false, Image.FORMAT_RGBA8)
	
	# Generate chalk-like texture
	for x in range(int(texture_size.x)):
		for y in range(int(texture_size.y)):
			var uv = Vector2(x / texture_size.x, y / texture_size.y)
			
			# Generate noise value
			var noise_value = noise.get_noise_2d(x * noise_scale, y * noise_scale)
			noise_value = (noise_value + 1.0) * 0.5  # Normalize to 0-1
			
			# Add some variation for chalk-like appearance
			var detail_noise = noise.get_noise_2d(x * noise_scale * 2.0, y * noise_scale * 2.0)
			detail_noise = (detail_noise + 1.0) * 0.5
			
			# Combine noise layers
			var final_noise = noise_value * (1.0 - texture_detail) + detail_noise * texture_detail
			
			# Calculate opacity with variation
			var opacity = 1.0 - (final_noise * opacity_variation)
			opacity = clamp(opacity, 0.1, 1.0)
			
			# Set pixel color
			var pixel_color = chalk_color
			pixel_color.a = opacity
			image.set_pixel(x, y, pixel_color)
	
	# Create texture from image
	chalk_texture = ImageTexture.create_from_image(image)

func get_texture() -> ImageTexture:
	return chalk_texture

func set_chalk_color(color: Color):
	chalk_color = color
	_generate_chalk_texture()

func set_noise_scale(scale: float):
	noise_scale = scale
	_generate_chalk_texture()

func set_opacity_variation(variation: float):
	opacity_variation = variation
	_generate_chalk_texture()
